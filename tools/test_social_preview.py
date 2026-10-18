import tempfile
import unittest
from pathlib import Path
from html.parser import HTMLParser
from install_social_preview import install, BASE, IMAGE, ROOT

class Metadata(HTMLParser):
    def __init__(self,text):
        super().__init__();self.tags=[];self.feed(text)
    def handle_starttag(self,tag,attrs):
        if tag=='meta':self.tags.append(dict(attrs))

class SocialPreviewTests(unittest.TestCase):
    def test_crawler_gets_real_image_without_running_javascript(self):
        with tempfile.TemporaryDirectory() as folder:
            site=Path(folder);page=site/'index.html'
            runtime='<canvas id="canvas"></canvas><script src="index.js"></script>'
            page.write_text('<html><head><title>Demo</title></head><body>'+runtime+'</body></html>')
            self.assertTrue(install(site,'demo'))
            tags=Metadata(page.read_text()).tags
            self.assertEqual(next(t['content'] for t in tags if t.get('property')=='og:image'),BASE+'social/'+IMAGE)
            self.assertEqual((site/'social'/IMAGE).read_bytes(),(ROOT/'web/social'/IMAGE).read_bytes())
            self.assertIn(runtime,page.read_text())
            original=page.read_text();install(site,'demo');self.assertEqual(original,page.read_text())
    def test_full_edition_does_not_claim_two_night_demo(self):
        with tempfile.TemporaryDirectory() as folder:
            site=Path(folder);(site/'index.html').write_text('<head></head>')
            install(site,'full');text=(site/'index.html').read_text()
            self.assertIn('七星旅程',text);self.assertNotIn('兩個夜晚',text);self.assertNotIn('og:url',text)
    def test_old_release_redeployment_is_not_rebranded(self):
        with tempfile.TemporaryDirectory() as folder:
            site=Path(folder);page=site/'index.html';page.write_text('<head>old</head>')
            self.assertFalse(install(site,'demo',tag='v0.0.58'))
            self.assertEqual(page.read_text(),'<head>old</head>');self.assertFalse((site/'social').exists())

if __name__=='__main__':unittest.main()
