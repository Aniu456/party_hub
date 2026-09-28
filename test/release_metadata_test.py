import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "release_metadata", Path(__file__).resolve().parent.parent / "tool/release_metadata.py"
)
release_metadata = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release_metadata)


class ReleaseVersionTest(unittest.TestCase):
    def test_download_base_requires_https_and_no_extra_url_components(self):
        base = "https://example.com/work/party-hub/downloads"
        self.assertEqual(release_metadata.validate_download_base(base), base)
        for value in ["http://example.com", base + "/", base + "?x=1", base + "#x",
                      "https://user:secret@localhost", "https:///downloads", base + "/../other"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                release_metadata.validate_download_base(value)

    def test_matches_pubspec(self):
        self.assertEqual(
            release_metadata.release_version("version: 1.2.3+42\n", "v1.2.3+42"),
            ("1.2.3", 42),
        )

    def test_rejects_mismatches_and_invalid_android_versions(self):
        for value, tag in [
            ("1.2.3+42", "v1.2.3+43"),
            ("1.2.3+42", "v1.2.3"),
            ("1.2.3+0", "v1.2.3+0"),
            ("1.2.3+2100000001", "v1.2.3+2100000001"),
            ("1.2.3-beta+42", "v1.2.3-beta+42"),
        ]:
            with self.subTest(value=value, tag=tag), self.assertRaises(ValueError):
                release_metadata.release_version(f"version: {value}\n", tag)


if __name__ == "__main__":
    unittest.main()
