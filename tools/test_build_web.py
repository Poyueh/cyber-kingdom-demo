import re
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from build_web import export_project, validate_export

class WebBuildTests(unittest.TestCase):
    def test_export_bundles_page_assets_from_committed_source(self):
        from build_web import PAGE_ASSETS, install_page_assets
        with tempfile.TemporaryDirectory() as folder:
            stage=Path(folder)/'source'; web=Path(folder)/'web'
            (stage/'web').mkdir(parents=True); web.mkdir()
            for name in PAGE_ASSETS:
                (stage/'web'/name).write_text('committed '+name)
            install_page_assets(stage,web)
            for name in PAGE_ASSETS:
                self.assertEqual((web/name).read_text(),'committed '+name)
            (stage/'web/guide-reader.js').unlink()
            with self.assertRaises(FileNotFoundError):install_page_assets(stage,web)

    def test_page_shell_guards_phone_swipes(self):
        # A downward swipe invests crystals; it must never pull-to-refresh the page.
        from build_web import PAGE_ASSETS
        root=Path(__file__).resolve().parents[1]
        head=re.search(r'^html/head_include="(.*)"$',(root/'export_presets.cfg').read_text(),re.M).group(1)
        for name in ('touch-guard.css','touch-guard.js','guide-reader.css','guide-reader.js'):
            self.assertIn(name,PAGE_ASSETS)
            self.assertIn(name,head)
        css=(root/'web/touch-guard.css').read_text()
        self.assertIn('overscroll-behavior: none',css)
        script=(root/'web/touch-guard.js').read_text()
        self.assertIn("'touchmove'",script);self.assertIn('passive: false',script)

    def test_page_shell_caps_phone_pixel_ratio(self):
        # 3x phone screens would fill 2.25x more pixels than 2x for no visible gain in pixel art.
        from build_web import PAGE_ASSETS
        root=Path(__file__).resolve().parents[1]
        head=re.search(r'^html/head_include="(.*)"$',(root/'export_presets.cfg').read_text(),re.M).group(1)
        self.assertIn('phone-display.js',PAGE_ASSETS)
        self.assertLess(head.index('phone-display.js'),head.index('touch-guard.js'),'cap applies before anything reads the ratio')
        script=(root/'web/phone-display.js').read_text()
        for name in ('devicePixelRatio','maxTouchPoints','MAX_PHONE_RATIO = 2'):self.assertIn(name,script)

    def test_page_shell_caps_frames_without_blocking(self):
        # Engine.max_fps busy-waits on a single-threaded page; the cap skips animation frames instead.
        from build_web import PAGE_ASSETS
        root=Path(__file__).resolve().parents[1]
        head=re.search(r'^html/head_include="(.*)"$',(root/'export_presets.cfg').read_text(),re.M).group(1)
        self.assertIn('frame-pacing.js',PAGE_ASSETS);self.assertIn('frame-pacing.js',head)
        script=(root/'web/frame-pacing.js').read_text()
        for name in ('requestAnimationFrame','CyberKingdomFrames','cap:'):self.assertIn(name,script)
        pacing=(root/'bootstrap/frame_pacing.gd').read_text()
        self.assertNotIn('max_fps =',pacing);self.assertIn('CyberKingdomFrames',pacing)

    def test_page_shell_switches_fullscreen_inside_the_players_gesture(self):
        # Browsers only allow fullscreen within a tap or click; Godot handles buttons a frame later.
        from build_web import PAGE_ASSETS
        root=Path(__file__).resolve().parents[1]
        head=re.search(r'^html/head_include="(.*)"$',(root/'export_presets.cfg').read_text(),re.M).group(1)
        self.assertIn('fullscreen.js',PAGE_ASSETS);self.assertIn('fullscreen.js',head)
        self.assertIn('apple-mobile-web-app-capable',head)
        script=(root/'web/fullscreen.js').read_text()
        for name in ("'pointerup'","'touchend'",'arm','requestFullscreen','webkitRequestFullscreen'):self.assertIn(name,script)

    def test_existing_output_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as folder:
            output=Path(folder); marker=output/'player-save';marker.write_text('keep')
            with patch('build_web.prepare_tree') as stage:
                with self.assertRaises(FileExistsError):export_project('HEAD',output,'unused')
                stage.assert_not_called()
            self.assertEqual(marker.read_text(),'keep')

    def test_incomplete_or_invalid_runtime_is_not_deliverable(self):
        with tempfile.TemporaryDirectory() as folder:
            web=Path(folder)
            for name in ['index.html','index.js','index.pck']: (web/name).write_bytes(b'content')
            with self.assertRaises(ValueError):validate_export(web)
            (web/'index.wasm').write_bytes(b'not a wasm program')
            with self.assertRaises(ValueError):validate_export(web)
            (web/'index.wasm').write_bytes(b'\x00asm\x01\x00\x00\x00')
            validate_export(web)
            (web/'index.pck').write_bytes(b'')
            with self.assertRaises(ValueError):validate_export(web)

if __name__=='__main__':unittest.main()
