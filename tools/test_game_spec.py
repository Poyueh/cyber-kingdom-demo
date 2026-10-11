"""Behavior checks for the published specification and its review gate."""
import json
from pathlib import Path
import tempfile
import unittest
from build_game_spec import record_review, validate_review, build, publish_spec


class SpecificationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'repo'
        for directory in ('docs/game-spec', 'domain', 'web/game-spec'):
            (self.root / directory).mkdir(parents=True)
        (self.root / 'export_presets.cfg').write_text('application/short_version="0.0.38"\n')
        (self.root / 'domain/rule.gd').write_text('var cost = 2\n')
        for filename in ('style.css', 'reader.js'):
            (self.root / 'web/game-spec' / filename).write_text('/* fixture */')
        self.content = {'game_version': '0.0.38', 'revision': 1, 'updated': '2026-10-11',
                        'review_note': 'Initial verified rules', 'sections': [
                            {'id': 'loop', 'title': 'Play <loop>', 'summary': 'Read & explore',
                             'status': 'current', 'blocks': [{'type': 'p', 'text': '<script>bad()</script>'}]}]}
        self.save()
        record_review(self.root)

    def save(self):
        (self.root / 'docs/game-spec/content.json').write_text(json.dumps(self.content))

    def test_changed_rule_requires_content_revision_and_new_review(self):
        (self.root / 'domain/rule.gd').write_text('var cost = 3\n')
        with self.assertRaisesRegex(ValueError, 'review'): validate_review(self.root)
        with self.assertRaisesRegex(ValueError, 'revision'): record_review(self.root)
        self.content['revision'] = 2
        self.content['review_note'] = 'Cost changed to three'
        self.save()
        record_review(self.root)
        validate_review(self.root)
        (self.root / 'domain/new_rule.gd').write_text('var bonus = 1\n')
        with self.assertRaises(ValueError): validate_review(self.root)

    def test_project_input_changes_require_review_but_export_cosmetics_do_not(self):
        project = self.root / 'project.godot'
        project.write_text('[application]\nconfig/name="Cyber Kingdom"\n[input]\naction=1\n')
        self.content['revision'] = 2
        self.content['review_note'] = 'Review project input settings'
        self.save()
        record_review(self.root)
        project.write_text('[application]\nconfig/name="Cyber Kingdom Demo"\nconfig/icon="res://art/ui/app-icon.svg"\n[input]\naction=1\n')
        validate_review(self.root)
        project.write_text(project.read_text().replace('action=1', 'action=2'))
        with self.assertRaisesRegex(ValueError, 'review'): validate_review(self.root)

    def test_content_edit_also_needs_review(self):
        self.content['sections'][0]['summary'] = 'Changed claim'
        self.save()
        with self.assertRaises(ValueError): validate_review(self.root)

    def test_version_mismatch_never_modifies_existing_game(self):
        site = Path(self.temp.name) / 'site'
        site.mkdir()
        (site / 'index.pck').write_bytes(b'original game')
        with self.assertRaisesRegex(ValueError, 'version'): publish_spec(self.root, site, 'v0.0.39')
        self.assertEqual((site / 'index.pck').read_bytes(), b'original game')
        self.assertFalse((site / 'spec').exists())

    def test_document_escapes_text_and_stays_inside_spec_directory(self):
        site = Path(self.temp.name) / 'site'
        site.mkdir()
        (site / 'index.html').write_text('original game')
        publish_spec(self.root, site, 'v0.0.38')
        page = (site / 'spec/index.html').read_text()
        self.assertIn('&lt;script&gt;', page)
        self.assertNotIn('<script>bad()', page)
        self.assertIn('id="loop"', page)
        self.assertEqual((site / 'index.html').read_text(), 'original game')
        # Re-deploy a bundled historic document without imposing current source content.
        (self.root / 'domain/rule.gd').write_text('newer unreleased source')
        publish_spec(self.root, site, 'v0.0.38')
        with self.assertRaises(ValueError): publish_spec(self.root, site, 'v0.0.38', refresh=True)
        self.assertEqual((site / 'spec/index.html').read_text(), page)
        (site / 'spec/index.html').write_text('corrupt bundle')
        with self.assertRaisesRegex(ValueError, 'integrity'): publish_spec(self.root, site, 'v0.0.38')

    def test_unsafe_asset_and_duplicate_anchor_are_rejected(self):
        self.content['sections'][0]['blocks'] = [{'type': 'figure', 'path': '../../private.png', 'caption': 'no'}]
        self.save()
        with self.assertRaises(ValueError): record_review(self.root)
        self.content['sections'][0]['blocks'] = []
        self.content['sections'].append(dict(self.content['sections'][0]))
        self.save()
        with self.assertRaises(ValueError): record_review(self.root)


if __name__ == '__main__': unittest.main()
