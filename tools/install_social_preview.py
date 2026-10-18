"""Add crawlable sharing metadata without changing the game runtime."""
import argparse
from html import escape
import json
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://poyueh.github.io/cyber-kingdom-demo/'
IMAGE = 'forest-companion-v59.png'
START, END = '<!-- social-preview:start -->', '<!-- social-preview:end -->'


def install(site: Path, edition: str, source: Path = ROOT, tag=None) -> bool:
    version = json.loads((source/'docs/game-spec/content.json').read_text())['game_version']
    # Redeploying an older release must keep its own metadata and assets.
    if tag is not None and tag != 'v'+version:
        return False
    page = site/'index.html'
    html = page.read_text(encoding='utf-8')
    if html.count('</head>') != 1:
        raise ValueError('Expected exactly one HTML head')
    title = 'Cyber Kingdom：最後的避難所' + ('｜森林免費試玩' if edition == 'demo' else '｜七星旅程')
    description = ('點燃營火、招募居民、探索森林遺跡，帶工匠封印龍門並擊敗森林巨龍。像素動作與聚落建設，電腦與手機瀏覽器免安裝試玩。' if edition == 'demo'
                   else '探索七顆星球、建立避難所，守護居民並挑戰古龍。像素動作與聚落建設的未知旅程。')
    tags = [('name','description',description),('property','og:type','website'),
            ('property','og:locale','zh_TW'),('property','og:site_name','Cyber Kingdom'),
            ('property','og:title',title),('property','og:description',description),
            ('property','og:image',BASE+'social/'+IMAGE),('property','og:image:type','image/png'),
            ('property','og:image:width','960'),('property','og:image:height','450'),
            ('property','og:image:alt','實際遊戲畫面：騎士、引導鬼魂與森林營火聚落'),
            ('name','twitter:card','summary_large_image'),('name','twitter:title',title),
            ('name','twitter:description',description),('name','twitter:image',BASE+'social/'+IMAGE)]
    # Pages serves the Demo at the site root and the main game under main/.
    tags.append(('property','og:url',BASE if edition == 'demo' else BASE+'main/'))
    block = START+'\n'+'\n'.join(f'<meta {kind}="{key}" content="{escape(value, quote=True)}">' for kind,key,value in tags)+'\n'+END
    html = re.sub(re.escape(START)+'.*?'+re.escape(END)+r'\s*','',html,flags=re.S)
    html = html.replace('</head>',block+'\n</head>')
    target=site/'social';target.mkdir(exist_ok=True)
    shutil.copyfile(source/'web/social'/IMAGE,target/IMAGE)
    page.write_text(html,encoding='utf-8')
    return True


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--site',type=Path,required=True)
    parser.add_argument('--edition',choices=['full','demo'],required=True)
    parser.add_argument('--tag')
    args=parser.parse_args()
    print('Installed gameplay sharing preview' if install(args.site,args.edition,tag=args.tag) else 'Kept older release preview unchanged')
