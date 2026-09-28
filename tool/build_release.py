"""Build signed Android + website + OTA files as one ZIP for the existing admin."""

import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile

from release_metadata import ROOT, release_version, validate_download_base

# Certificate of the original public Android release; never replace the key.
SIGNER_SHA256 = "dd9a04078d8cd08f28a3da4d9bdff9298075f6f2690a59b89614d0b788c78215"
ALLOWED_EXTENSIONS = {
    ".html", ".htm", ".js", ".mjs", ".css", ".json", ".map", ".wasm",
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".avif", ".ico",
    ".woff", ".woff2", ".ttf", ".otf", ".eot", ".mp4", ".webm", ".mp3",
    ".ogg", ".wav", ".pdf", ".txt", ".xml", ".webmanifest", ".apk", ".zip",
}


def run(*args, cwd=ROOT):
    subprocess.run([str(arg) for arg in args], cwd=cwd, check=True)


def package_site(web, apk, manifest, output):
    """Keep every runtime asset while matching the admin's ZIP allowlist."""
    version = manifest["version"]
    build = manifest["build_number"]
    apk_path = f"downloads/v{version}+{build}/party-hub.apk"
    with apk.open("rb") as handle:
        checksum = hashlib.file_digest(handle, "sha256").hexdigest()
    if checksum != manifest["sha256"]:
        raise ValueError("APK does not match the update manifest")
    files = {}
    renames = {}
    for file in sorted(web.rglob("*")):
        if file.is_symlink():
            raise ValueError(f"Symlink cannot be published: {file.name}")
        if not file.is_file():
            continue
        name = file.relative_to(web).as_posix()
        if name == ".last_build_id":
            continue
        if any(part.startswith(".") for part in name.split("/")) or any(c in name for c in "\\:\x00"):
            raise ValueError(f"Unsafe ZIP path: {name}")
        if file.suffix.lower() not in ALLOWED_EXTENSIONS:
            if file.suffix in {".bin", ".frag", ".symbols"} or name == "assets/NOTICES":
                renames[name] = name + ".txt"
            else:
                raise ValueError(f"Unsupported website resource: {name}")
        files[name] = file
    if "index.html" not in files:
        raise ValueError("Website build is missing index.html")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output.parent) as staging:
        archive = Path(staging) / "release.zip"
        with ZipFile(archive, "w", ZIP_DEFLATED) as bundle:
            for name, file in files.items():
                data = file.read_bytes()
                if file.suffix in {".js", ".json", ".html"}:
                    text = data.decode("utf-8")
                    for old, new in renames.items():
                        for quote in ['"', "'"]:
                            text = text.replace(quote + old + quote, quote + new + quote)
                            text = text.replace(
                                quote + old.removeprefix("assets/") + quote,
                                quote + new.removeprefix("assets/") + quote,
                            )
                    if name == "index.html":
                        text = text.replace('href="downloads/party-hub.apk"', f'href="{apk_path}"')
                    data = text.encode("utf-8")
                bundle.writestr(renames.get(name, name), data)
            bundle.write(apk, apk_path)
            bundle.writestr("downloads/update.json", json.dumps(manifest, indent=2) + "\n")
            bundle.writestr("downloads/SHA256SUMS.txt", f"{checksum}  party-hub.apk\n")
            bundle.writestr("downloads/release.txt", (
                f"康师傅 Android {version}（构建 {build}）\n\n"
                f"下载地址：{manifest['apk_url']}\nSHA-256：{checksum}\n\n"
                "安装后可在用户中心检查更新。升级使用同一签名，保留本机昵称。\n"
                "iOS 暂未开放下载。\n"
            ))
        with ZipFile(archive) as bundle:
            entries = bundle.infolist()
            names = bundle.namelist()
            if len(names) != len(set(names)) or len(names) > 5000:
                raise ValueError("ZIP contains duplicate or too many files")
            if sum(entry.file_size for entry in entries) > 200 * 1024**2:
                raise ValueError("Expanded ZIP exceeds the admin's 200 MB limit")
            if archive.stat().st_size > 100 * 1024**2:
                raise ValueError("ZIP exceeds the admin's 100 MB upload limit")
            if bundle.testzip() is not None:
                raise ValueError("ZIP integrity check failed")
        archive.replace(output)


def main():
    config = ROOT / ".env.production.json"
    settings = json.loads(config.read_text())
    base = validate_download_base(settings["PARTY_HUB_DOWNLOAD_BASE"])
    if not settings.get("PARTY_HUB_WS", "").startswith("wss://"):
        raise ValueError("Production WSS configuration is required")
    for name in ["android/key.properties", "android/release.jks"]:
        if not (ROOT / name).is_file():
            raise ValueError(f"Missing existing signing material: {name}")
    pubspec = (ROOT / "pubspec.yaml").read_text()
    tag = "v" + re.search(r"^version: (\S+)$", pubspec, re.M).group(1)
    version, build = release_version(pubspec, tag)
    output = ROOT / "build/releases" / tag
    run(sys.executable, "tool/release_metadata.py", "--tag", tag,
        "--download-base", base, "--check-remote")
    run("flutter", "build", "apk", "--release", f"--dart-define-from-file={config}")
    apk = ROOT / "build/app/outputs/flutter-apk/app-release.apk"
    sdk = re.search(r"^sdk.dir=(.+)$", (ROOT / "android/local.properties").read_text(), re.M).group(1)
    build_tools = sorted((Path(sdk) / "build-tools").glob("*/apksigner"),
                         key=lambda p: tuple(int(n) for n in re.findall(r"\d+", p.parent.name)))
    signer = subprocess.check_output([str(build_tools[-1]), "verify", "--print-certs", str(apk)], text=True)
    certificates = re.findall(r"certificate SHA-256 digest: ([0-9a-f]+)", signer)
    if certificates != [SIGNER_SHA256]:
        raise ValueError("APK signing certificate differs from the original release")
    aapt = build_tools[-1].with_name("aapt")
    badging = subprocess.check_output([str(aapt), "dump", "badging", str(apk)], text=True)
    expected = f"package: name='com.example.party_hub' versionCode='{build}' versionName='{version}'"
    if not badging.startswith(expected):
        raise ValueError("APK package ID or version does not match pubspec.yaml")
    run(sys.executable, "tool/release_metadata.py", "--tag", tag,
        "--download-base", base, "--apk", apk, "--output-dir", output)
    run("flutter", "build", "web", "--release", "--no-web-resources-cdn",
        f"--dart-define=PARTY_HUB_APK_PATH=downloads/{tag}/party-hub.apk", cwd=ROOT / "website")
    # Recheck after building in case the server changed during this run.
    run(sys.executable, "tool/release_metadata.py", "--tag", tag,
        "--download-base", base, "--check-remote")
    manifest = json.loads((output / "update.json").read_text())
    archive = output / f"party-hub-{tag}-website-android.zip"
    package_site(ROOT / "website/build/web", apk, manifest, archive)
    print(f"Ready to upload to the existing work entry: {archive}")
    print("Nothing has been uploaded. Keep the existing work slug when replacing its ZIP.")


if __name__ == "__main__":
    main()
