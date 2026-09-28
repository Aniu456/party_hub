"""Check the Git index before publishing this public client repository."""

import ipaddress
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import urlparse

PRIVATE_PREFIXES = ("server/", "deploy/", "docs/private/", "docs/previews/", ".ssh/", ".codex/", ".agents/")
PRIVATE_FILES = {
    "play.md", "AGENTS.md", "lib/room_server.dart",
    "test/room_security_test.dart", "test/ui_flow_test.dart", "test/ui_layout_test.dart",
    "android/key.properties", "android/local.properties",
    "ios/Flutter/Signing.local.xcconfig",
}
PUBLIC_TOOLS = {"tool/release_metadata.py", "tool/check_public_files.py"}
PRIVATE_SUFFIXES = {".jks", ".keystore", ".pem", ".key", ".p8", ".p12", ".pfx", ".mobileprovision", ".db", ".sqlite", ".sql"}
PATTERNS = {
    "private key": r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "access token": r"(?:gh[pousr]_|github_pat_)[A-Za-z0-9_]{30,}",
    "personal filesystem path": r"/(?:Users|home)/[A-Za-z0-9_.-]+/",
    "literal signing team": r"DEVELOPMENT_TEAM\s*=\s*[A-Z0-9]{10}\s*;",
    "email address": r"[\w.+-]+@[\w.-]+\.(?!png\b|jpg\b|jpeg\b|webp\b|gif\b|svg\b)[A-Za-z]{2,}",
}


def main():
    subprocess.run(["git", "rev-parse", "--show-toplevel"], check=True, stdout=subprocess.DEVNULL)
    paths = subprocess.check_output(["git", "ls-files", "-z"]).decode().split("\0")
    local_host = None
    config = Path(".env.production.json")
    if config.exists():
        local_host = urlparse(json.loads(config.read_text())["PARTY_HUB_WS"]).hostname
    failures = []
    for name in filter(None, paths):
        path = Path(name)
        if (name.startswith(PRIVATE_PREFIXES) or name in PRIVATE_FILES
                or path.name.startswith(".env") or path.suffix in PRIVATE_SUFFIXES
                or (name.startswith("tool/") and name not in PUBLIC_TOOLS)):
            failures.append((name, "private file tracked by Git"))
            continue
        raw = subprocess.check_output(["git", "show", f":{name}"])
        content = raw.decode("utf-8", errors="ignore")
        for label, pattern in PATTERNS.items():
            if label == "email address" and b"\0" in raw:
                continue
            if re.search(pattern, content):
                failures.append((name, label))
        if local_host and local_host in content:
            failures.append((name, "production hostname"))
        for address in re.findall(r"(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?![\w.])", content):
            try:
                parsed = ipaddress.ip_address(address)
            except ValueError:
                continue
            if not parsed.is_loopback and not parsed.is_unspecified:
                failures.append((name, "non-loopback IP address"))
        for host in re.findall(r"wss?://([^/\s'\"`]+)", content):
            if host.split(":", 1)[0] not in {"127.0.0.1", "localhost", "example.invalid"}:
                failures.append((name, "hardcoded WebSocket host"))
    if failures:
        for name, reason in sorted(set(failures)):
            print(f"{name}: {reason}")
        raise SystemExit("Public file check failed; no matched private values were printed.")
    print("Public file check passed: no excluded paths or recognized private identifiers in the Git index.")


if __name__ == "__main__":
    main()
