import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "release_metadata", Path(__file__).resolve().parent.parent / "tool/release_metadata.py"
)
release_metadata = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release_metadata)


class ReleaseVersionTest(unittest.TestCase):
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
