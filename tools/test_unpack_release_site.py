import hashlib
import tempfile
import unittest
import zipfile
from pathlib import Path
from unpack_release_site import unpack

RUNTIME = ('index.html', 'index.js', 'index.wasm', 'index.pck', 'guide.html')


def archive(folder: Path, name: str, files=RUNTIME, marker='demo') -> Path:
    path = folder/name
    with zipfile.ZipFile(path, 'w') as bundle:
        for file in files:
            bundle.writestr(file, marker+':'+file)
    return path


def checksums(folder: Path, *paths: Path, wrong=()) -> None:
    lines = [('0'*64 if p.name in wrong else hashlib.sha256(p.read_bytes()).hexdigest())+'  '+p.name for p in paths]
    (folder/'SHA256SUMS.txt').write_text('\n'.join(lines)+'\n')


class UnpackReleaseSiteTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.release = Path(self.folder.name)/'release'
        self.site = Path(self.folder.name)/'_site'
        self.release.mkdir();self.site.mkdir()

    def tearDown(self):
        self.folder.cleanup()

    def test_demo_at_root_and_main_under_main(self):
        demo = archive(self.release, 'Cyber-Kingdom-Demo-Web-v0.0.61.zip')
        main = archive(self.release, 'Cyber-Kingdom-Main-Web-v0.0.61.zip', marker='main')
        checksums(self.release, demo, main)
        result = unpack(self.release, self.site)
        self.assertEqual((self.site/'index.pck').read_text(), 'demo:index.pck')
        self.assertEqual((self.site/'main/index.pck').read_text(), 'main:index.pck')
        self.assertTrue((self.site/'.nojekyll').is_file())
        self.assertEqual(result, {'demo': demo.name, 'main': main.name})

    def test_older_release_without_main_still_deploys(self):
        legacy = archive(self.release, 'Cyber-Kingdom-Web-v0.0.38.zip')
        checksums(self.release, legacy)
        self.assertEqual(unpack(self.release, self.site), {'demo': legacy.name, 'main': None})
        self.assertFalse((self.site/'main').exists())

    def test_main_checksum_mismatch_stops_deployment(self):
        demo = archive(self.release, 'Cyber-Kingdom-Demo-Web-v0.0.61.zip')
        main = archive(self.release, 'Cyber-Kingdom-Main-Web-v0.0.61.zip', marker='main')
        checksums(self.release, demo, main, wrong=(main.name,))
        with self.assertRaises(SystemExit):
            unpack(self.release, self.site)

    def test_unsafe_paths_and_missing_runtime_are_refused(self):
        demo = archive(self.release, 'Cyber-Kingdom-Demo-Web-v0.0.61.zip', files=RUNTIME+('../escape.txt',))
        checksums(self.release, demo)
        with self.assertRaises(SystemExit):
            unpack(self.release, self.site)
        self.assertFalse((Path(self.folder.name)/'escape.txt').exists())
        (self.release/demo.name).unlink()
        main = archive(self.release, 'Cyber-Kingdom-Main-Web-v0.0.61.zip', files=RUNTIME[:-1], marker='main')
        demo = archive(self.release, 'Cyber-Kingdom-Demo-Web-v0.0.61.zip')
        checksums(self.release, demo, main)
        with self.assertRaises(SystemExit):
            unpack(self.release, self.site)


if __name__ == '__main__':
    unittest.main()
