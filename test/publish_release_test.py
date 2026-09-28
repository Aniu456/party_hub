import sys
from pathlib import Path
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / 'tool'))
from publish_release import next_version, read_manifest, publish


class AutoReleaseTest(unittest.TestCase):
    def test_allocates_build_without_lowering_declared_version(self):
        for declared, remote, expected in [(3, 2, 3), (3, 3, 4), (3, 10, 11), (20, 10, 20)]:
            updated, tag = next_version(f'version: 1.0.2+{declared}\n', {'version': '1.0.1', 'build_number': remote})
            self.assertEqual(tag, f'v1.0.2+{expected}')
            self.assertEqual(updated, f'version: 1.0.2+{expected}\n')

    def test_rejects_downgrade_malformed_manifest_and_overflow(self):
        for previous in [
            {'version': '2.0.0', 'build_number': 3},
            {'version': '1.0.0', 'build_number': True},
            {'version': '1.0.0', 'build_number': 2100000000},
            {'version': 'invalid', 'build_number': 3},
        ]:
            with self.subTest(previous=previous), self.assertRaises(ValueError):
                next_version('version: 1.0.2+3\n', previous)

    def test_network_failure_is_not_an_empty_release(self):
        with patch('publish_release.urlopen', side_effect=URLError('offline')):
            with self.assertRaises(URLError):
                read_manifest('https://example.com/downloads')
        with patch('publish_release.urlopen', side_effect=HTTPError('', 404, '', {}, None)):
            self.assertIsNone(read_manifest('https://example.com/downloads'))

    def test_deploy_host_cannot_inject_ssh_options(self):
        for host in ['-oProxyCommand=bad', 'host;cmd', 'user@host', '', None]:
            with self.assertRaises(ValueError):
                publish(None, '', host, None, None)


if __name__ == '__main__':
    unittest.main()
