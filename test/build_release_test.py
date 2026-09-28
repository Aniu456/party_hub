import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from zipfile import ZipFile

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tool"))
from build_release import package_site


class ReleaseBundleTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.web = self.root / "web"
        (self.web / "assets").mkdir(parents=True)
        (self.web / "index.html").write_text('<a href="downloads/party-hub.apk">Download</a>')
        (self.web / "main.dart.js").write_text('load("NOTICES");load("AssetManifest.bin.json");')
        (self.web / "assets/NOTICES").write_bytes(b"licenses")
        (self.web / "assets/AssetManifest.bin").write_bytes(b"manifest")
        (self.web / "assets/AssetManifest.bin.json").write_text('"manifest"')
        (self.web / ".last_build_id").write_text("internal")
        self.apk = self.root / "party-hub.apk"
        self.apk.write_bytes(b"test APK bytes")
        self.manifest = {
            "version": "1.0.1", "build_number": 2,
            "apk_url": "https://example.com/downloads/v1.0.1+2/party-hub.apk",
            "sha256": hashlib.sha256(self.apk.read_bytes()).hexdigest(),
        }
        self.output = self.root / "release.zip"

    def test_complete_bundle_preserves_bytes_and_fixes_runtime_references(self):
        package_site(self.web, self.apk, self.manifest, self.output)
        with ZipFile(self.output) as archive:
            self.assertNotIn(".last_build_id", archive.namelist())
            self.assertEqual(archive.read("downloads/v1.0.1+2/party-hub.apk"), self.apk.read_bytes())
            self.assertEqual(json.loads(archive.read("downloads/update.json")), self.manifest)
            self.assertEqual(archive.read("assets/NOTICES.txt"), b"licenses")
            self.assertIn(b'load("NOTICES.txt")', archive.read("main.dart.js"))
            self.assertIn(b'load("AssetManifest.bin.json")', archive.read("main.dart.js"))
            self.assertIn(b'href="downloads/v1.0.1+2/party-hub.apk"', archive.read("index.html"))
            self.assertIn(self.manifest["sha256"].encode(), archive.read("downloads/SHA256SUMS.txt"))

    def test_bad_checksum_cannot_replace_existing_bundle(self):
        self.output.write_bytes(b"existing")
        self.apk.write_bytes(b"modified")
        with self.assertRaises(ValueError):
            package_site(self.web, self.apk, self.manifest, self.output)
        self.assertEqual(self.output.read_bytes(), b"existing")

    def test_hidden_files_and_symlinks_are_rejected(self):
        hidden = self.web / ".env"
        hidden.write_text("must not publish")
        with self.assertRaises(ValueError):
            package_site(self.web, self.apk, self.manifest, self.output)
        hidden.unlink()
        (self.web / "linked.txt").symlink_to(self.apk)
        with self.assertRaises(ValueError):
            package_site(self.web, self.apk, self.manifest, self.output)


if __name__ == "__main__":
    unittest.main()
