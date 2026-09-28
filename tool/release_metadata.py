"""Validate a release tag and produce the manifest consumed by Android."""

import argparse
import hashlib
import json
import re
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import urlopen

REPOSITORY = "Aniu456/party_hub"
ROOT = Path(__file__).resolve().parent.parent


def validate_download_base(value):
    url = urlsplit(value)
    if (url.scheme != "https" or not url.hostname or url.username or url.password
            or url.query or url.fragment or value.endswith("/")
            or any(part in {".", ".."} for part in url.path.split("/"))):
        raise ValueError("Download base must be an HTTPS URL without credentials, query, fragment or trailing slash")
    return value


def release_version(pubspec, tag):
    match = re.search(r"^version: (\d+\.\d+\.\d+)\+([1-9]\d*)\s*$", pubspec, re.M)
    if not match:
        raise ValueError("pubspec.yaml version must be MAJOR.MINOR.PATCH+BUILD")
    version, build = match.groups()
    if tag != f"v{version}+{build}":
        raise ValueError("Release tag must exactly match v + pubspec.yaml version")
    if int(build) > 2100000000:
        raise ValueError("Android build number exceeds versionCode limit")
    return version, int(build)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--check-remote", action="store_true")
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--download-base", type=validate_download_base)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "build/release")
    args = parser.parse_args()
    version, build = release_version((ROOT / "pubspec.yaml").read_text(), args.tag)
    if args.check_remote:
        # Only 404 means no release exists; network failures must stop publication.
        url = (f"{args.download_base}/update.json" if args.download_base else
               f"https://github.com/{REPOSITORY}/releases/latest/download/update.json")
        try:
            with urlopen(url, timeout=20) as response:
                previous = json.load(response)
        except HTTPError as error:
            if error.code != 404:
                raise
        else:
            previous_build = previous.get("build_number")
            if type(previous_build) is not int or build <= previous_build:
                raise ValueError("Build number must exceed the latest public release")
    if args.apk:
        with args.apk.open("rb") as apk:
            checksum = hashlib.file_digest(apk, "sha256").hexdigest()
        manifest = {
            "version": version,
            "build_number": build,
            "apk_url": f"{args.download_base or f'https://github.com/{REPOSITORY}/releases/download'}/{args.tag}/party-hub.apk",
            "sha256": checksum,
        }
        args.output_dir.mkdir(parents=True, exist_ok=True)
        (args.output_dir / "update.json").write_text(
            json.dumps(manifest, indent=2) + "\n"
        )
        (args.output_dir / "SHA256SUMS").write_text(f"{checksum}  party-hub.apk\n")
    print(f"Release metadata validated: {version}+{build}")


if __name__ == "__main__":
    main()
