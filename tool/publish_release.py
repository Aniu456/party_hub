"""Prepare a monotonic version and publish a complete bundle to the configured server."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from zipfile import ZipFile

from release_metadata import ROOT, release_version, validate_download_base


def read_manifest(base):
    request = Request(base + '/update.json', headers={'Cache-Control': 'no-cache'})
    try:
        with urlopen(request, timeout=30) as response:
            return json.load(response)
    except HTTPError as error:
        if error.code == 404:
            return None
        raise


def next_version(pubspec, previous):
    match = re.search(r'^version: (\S+)$', pubspec, re.M)
    if not match:
        raise ValueError('Missing pubspec version')
    version, build = release_version(pubspec, 'v' + match[1])
    if previous is not None:
        old = previous.get('build_number')
        old_version = previous.get('version', '')
        if type(old) is not int or old < 1 or not re.fullmatch(r'\d+\.\d+\.\d+', old_version):
            raise ValueError('Invalid public update manifest')
        if tuple(map(int, version.split('.'))) < tuple(map(int, old_version.split('.'))):
            raise ValueError('Cannot publish an older version name')
        build = max(build, old + 1)
    tag = f'v{version}+{build}'
    updated = re.sub(r'^version: \S+$', f'version: {version}+{build}', pubspec, count=1, flags=re.M)
    release_version(updated, tag)
    return updated, tag


def publish(archive, base, host, identity, known_hosts):
    if not host or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]*', host):
        raise ValueError('Invalid deployment host')
    with ZipFile(archive) as bundle:
        expected = json.loads(bundle.read('downloads/update.json'))
    previous = read_manifest(base)
    if previous is not None and previous != expected and previous['build_number'] >= expected['build_number']:
        raise ValueError('A newer or conflicting version is already published')
    # The dedicated SSH key can only invoke the fixed server-side publisher.
    with open(archive, 'rb') as source:
        subprocess.run([
            'ssh', '-F', '/dev/null', '-i', str(identity),
            '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
            '-o', 'StrictHostKeyChecking=yes', '-o', f'UserKnownHostsFile={known_hosts}',
            '-o', 'ConnectTimeout=20', '-o', 'ServerAliveInterval=15',
            '-o', 'ServerAliveCountMax=4', f'root@{host}', 'publish',
        ], stdin=source, check=True, timeout=600)
    actual = read_manifest(base)
    if actual != expected:
        raise ValueError('Public update manifest does not match the uploaded release')
    tag = f"v{expected['version']}+{expected['build_number']}"
    if expected['apk_url'] != f'{base}/{tag}/party-hub.apk':
        raise ValueError('Unexpected public APK address')
    digest = hashlib.sha256()
    with urlopen(expected['apk_url'], timeout=60) as response:
        for chunk in iter(lambda: response.read(1024 * 1024), b''):
            digest.update(chunk)
    if digest.hexdigest() != expected['sha256']:
        raise ValueError('Public APK checksum mismatch')
    print(f'Published and verified {tag}: server manifest and downloaded APK match.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--archive', type=Path)
    parser.add_argument('--host', default=os.environ.get('PARTY_HUB_DEPLOY_HOST'))
    parser.add_argument('--identity', type=Path)
    parser.add_argument('--known-hosts', type=Path)
    args = parser.parse_args()
    base = validate_download_base(json.loads((ROOT / '.env.production.json').read_text())['PARTY_HUB_DOWNLOAD_BASE'])
    if args.prepare:
        pubspec = ROOT / 'pubspec.yaml'
        updated, tag = next_version(pubspec.read_text(), read_manifest(base))
        pubspec.write_text(updated)
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
                output.write(f'tag={tag}\n')
        print(f'Prepared {tag}')
    else:
        if not all([args.archive, args.identity, args.known_hosts]):
            parser.error('--archive, --identity and --known-hosts are required')
        publish(args.archive, base, args.host, args.identity, args.known_hosts)


if __name__ == '__main__':
    main()
