import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from apply_loading_logo import apply, snapshot


class LoadingLogoTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.site = self.root / 'site'; self.site.mkdir()
        self.branding = self.root / 'branding'; self.branding.mkdir()
        (self.site / 'main').mkdir()
        for path in ('index.png', 'loading-illustration.css', 'index.pck', 'index.wasm', 'index.html', 'main/index.png', 'main/index.pck'):
            (self.site / path).write_bytes(('original ' + path).encode())
        d = {'schema': 1, 'scope': 'forest-demo-loading-only', 'label': 'v0.0.85-logo1', 'base_release': 'v0.0.85', 'runtime_game_version': '0.0.85', 'runtime_spec_revision': 218, 'assets': {}, 'original': {}}
        for p in ('index.png', 'loading-illustration.css'):
            data = ('new ' + p).encode(); (self.branding / p).write_bytes(data)
            d['assets'][p] = {'file': p, 'sha256': hashlib.sha256(data).hexdigest()}
            d['original'][p] = hashlib.sha256((self.site / p).read_bytes()).hexdigest()
        (self.branding / 'logo-trial.json').write_text(json.dumps(d))

    def tearDown(self):
        self.temp.cleanup()

    def test_changes_only_root_loading_assets(self):
        before = snapshot(self.site)
        result = apply(self.site, self.branding, 'v0.0.85')
        self.assertEqual(result['changed_files'], ['index.png', 'loading-illustration.css'])
        after = snapshot(self.site)
        for p in before.keys() - {'index.png', 'loading-illustration.css'}:
            self.assertEqual(before[p], after[p])
        self.assertEqual(json.loads((self.site / 'logo-trial.json').read_text())['runtime_spec_revision'], 218)

    def test_corrupt_asset_makes_no_partial_change(self):
        (self.branding / 'loading-illustration.css').write_text('bad')
        before = snapshot(self.site)
        with self.assertRaises(ValueError): apply(self.site, self.branding, 'v0.0.85')
        self.assertEqual(before, snapshot(self.site))

    def test_wrong_base_makes_no_change(self):
        (self.site / 'index.png').write_text('wrong release')
        before = snapshot(self.site)
        with self.assertRaises(ValueError): apply(self.site, self.branding, 'v0.0.85')
        self.assertEqual(before, snapshot(self.site))

    def test_newer_release_does_not_reapply_old_logo(self):
        before = snapshot(self.site)
        self.assertEqual(apply(self.site, self.branding, 'v0.0.86')['status'], 'skipped')
        self.assertEqual(before, snapshot(self.site))

    def test_rejects_path_escape(self):
        p = self.branding / 'logo-trial.json'; d = json.loads(p.read_text())
        d['assets']['index.png']['file'] = '../bad'; p.write_text(json.dumps(d))
        before = snapshot(self.site)
        with self.assertRaises(ValueError): apply(self.site, self.branding, 'v0.0.85')
        self.assertEqual(before, snapshot(self.site))

if __name__ == '__main__': unittest.main()
