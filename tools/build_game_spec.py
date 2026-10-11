#!/usr/bin/env python3
"""Review, build and publish the versioned game specification (standard library only)."""
import argparse
import hashlib
from html import escape
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CONTENT = Path('docs/game-spec/content.json')
REVIEW = Path('docs/game-spec/sync.json')
# Project export cosmetics are normalized; input, entry scene and other settings
# still require review. Export platform versions are tracked without normalization.
SOURCE_DIRS = ('domain', 'application', 'bootstrap', 'presentation', 'infrastructure',
               'data', 'scenes', 'localization', 'art', 'docs/design', 'docs/player-guide/assets')
SOURCE_SUFFIXES = {'.gd', '.tres', '.tscn', '.json', '.md', '.png', '.webp', '.svg',
                   '.ogg', '.wav', '.mp3', '.ttf', '.otf', '.csv', '.gdshader'}
STATUS = {'current': '現行實作', 'legacy': '相容／歷史', 'pending': '待驗證／決策'}
REPO = 'https://github.com/Poyueh/cyber-kingdom-demo'


def digest(path):
    hasher = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''): hasher.update(chunk)
    return hasher.hexdigest()


def source_snapshot(root):
    paths = [root / 'export_presets.cfg']
    for folder in SOURCE_DIRS:
        paths.extend(p for p in (root / folder).rglob('*') if p.is_file() and p.suffix in SOURCE_SUFFIXES)
    result = {p.relative_to(root).as_posix(): digest(p) for p in sorted(paths)}
    project = root / 'project.godot'
    if project.exists():
        cosmetics = ('config/name=', 'config/icon=', 'textures/vram_compression/import_etc2_astc=')
        canonical = '\n'.join(line for line in project.read_text().splitlines() if not line.startswith(cosmetics))
        result['project.godot'] = hashlib.sha256(canonical.encode()).hexdigest()
    return result


def safe_source(root, relative):
    path = Path(relative)
    if path.is_absolute() or '..' in path.parts or not (root / path).resolve().is_relative_to(root.resolve()):
        raise ValueError('Unsafe specification source path: ' + relative)
    if not (root / path).is_file(): raise ValueError('Missing specification source: ' + relative)
    return root / path


def read_content(root):
    content = json.loads((root / CONTENT).read_text())
    versions = re.findall(r'^application/short_version="([^"]+)"', (root / 'export_presets.cfg').read_text(), re.M)
    if not versions or set(versions) != {content['game_version']}:
        raise ValueError('Specification game version does not match export version')
    if not re.fullmatch(r'\d+\.\d+\.\d+', content['game_version']): raise ValueError('Invalid game version')
    if not isinstance(content['revision'], int) or content['revision'] < 1: raise ValueError('Invalid revision')
    if not content['review_note'].strip(): raise ValueError('A review note is required')
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', content['updated']): raise ValueError('Invalid review date')
    ids = set()
    if not content['sections']: raise ValueError('Specification has no chapters')
    for section in content['sections']:
        key = section['id']
        if not re.fullmatch(r'[a-z][a-z0-9-]*', key) or key in ids: raise ValueError('Invalid or duplicate chapter anchor')
        ids.add(key)
        if section['status'] not in STATUS: raise ValueError('Unknown chapter status')
        for ref in section.get('refs', []): safe_source(root, ref)
        for block in section['blocks']:
            kind = block['type']
            if kind not in {'p', 'heading', 'note', 'list', 'table', 'figure', 'flow', 'route'}:
                raise ValueError('Unknown content block: ' + kind)
            if kind == 'figure':
                path = safe_source(root, block['path'])
                if path.suffix not in {'.webp', '.png', '.jpg'}: raise ValueError('Unsupported image')
            if kind == 'table' and any(len(row) != len(block['headers']) for row in block['rows']):
                raise ValueError('Table column count mismatch')
    return content


def record_review(root):
    content = read_content(root)
    path = root / REVIEW
    if path.exists():
        previous = json.loads(path.read_text())
        if previous['content_sha256'] != digest(root / CONTENT) or previous['sources'] != source_snapshot(root):
            if content['revision'] <= previous['revision'] or content['review_note'] == previous['review_note']:
                raise ValueError('Update specification revision and review note before recording a changed review')
    manifest = {'schema': 1, 'game_version': content['game_version'], 'revision': content['revision'],
                'review_note': content['review_note'], 'content_sha256': digest(root / CONTENT),
                'sources': source_snapshot(root)}
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')


def validate_review(root):
    content = read_content(root)
    path = root / REVIEW
    if not path.is_file(): raise ValueError('Specification review is missing; review content and record it first')
    review = json.loads(path.read_text())
    current = source_snapshot(root)
    if review['sources'] != current or review['content_sha256'] != digest(root / CONTENT):
        changed = sorted(k for k in current.keys() | review['sources'].keys() if current.get(k) != review['sources'].get(k))
        raise ValueError('Specification review is stale. Update affected chapters, revision and review note, then run --record-review. Changed: ' + ', '.join(changed[:12]))
    if review['game_version'] != content['game_version'] or review['revision'] != content['revision']:
        raise ValueError('Specification review metadata mismatch')
    return content


def block_html(block, root, output):
    kind = block['type']
    if kind in ('p', 'heading', 'note'):
        tag = 'h3' if kind == 'heading' else 'p'
        return f'<{tag} class="{kind}">{escape(block["text"])}</{tag}>'
    if kind in ('list', 'flow'):
        tag = 'ol' if kind == 'flow' else 'ul'
        return f'<{tag} class="{kind}">' + ''.join('<li>' + escape(t) + '</li>' for t in block['items']) + f'</{tag}>'
    if kind == 'table':
        heads = ''.join('<th scope="col">' + escape(t) + '</th>' for t in block['headers'])
        rows = ''
        for row in block['rows']:
            cells = '<th scope="row">' + escape(row[0]) + '</th>'
            cells += ''.join('<td>' + escape(t) + '</td>' for t in row[1:])
            rows += '<tr>' + cells + '</tr>'
        return '<div class="table-wrap" tabindex="0" role="region" aria-label="可橫向捲動的規格表"><table><thead><tr>' + heads + '</tr></thead><tbody>' + rows + '</tbody></table></div>'
    if kind == 'figure':
        source = safe_source(root, block['path'])
        name = digest(source)[:10] + '-' + source.name
        shutil.copyfile(source, output / 'assets' / name)
        dimensions = f' width="{int(block["width"])}" height="{int(block["height"])}"'
        return f'<figure><img loading="lazy"{dimensions} src="assets/{escape(name)}" alt="{escape(block["caption"])}"><figcaption>{escape(block["caption"])}</figcaption></figure>'
    if kind == 'route':
        branches = ''.join('<span>' + ' <b>→</b> '.join(escape(t) for t in row) + '</span>' for row in block['branches'])
        end = ' <b>→</b> '.join(escape(t) for t in [block['merge']] + block['end'])
        return f'<div class="route"><div class="route-origin">{escape(block["origin"])}</div><div class="route-branches">{branches}</div><div class="route-end">{end}</div></div>'
    raise ValueError('Unsupported block')


def build(root, output, expected_version=None, source_ref=None):
    content = validate_review(root)
    version = content['game_version']
    if expected_version and expected_version.removeprefix('v') != version: raise ValueError('Release version and specification version differ')
    if source_ref is None:
        try: source_ref = subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True, stderr=subprocess.DEVNULL).strip()
        except subprocess.CalledProcessError: source_ref = 'v' + version
    if not re.fullmatch(r'[a-zA-Z0-9._/-]+', source_ref): raise ValueError('Invalid source reference')
    output.mkdir(parents=True, exist_ok=False)
    (output / 'assets').mkdir()
    nav, chapters = [], []
    for index, section in enumerate(content['sections'], 1):
        key, title = section['id'], escape(section['title'])
        nav.append(f'<a href="#{key}" data-chapter="{key}"><span>{index:02}</span>{title}</a>')
        blocks = ''.join(block_html(b, root, output) for b in section['blocks'])
        refs = ''.join(f'<a href="{REPO}/blob/{source_ref}/{escape(ref)}">{escape(Path(ref).name)}</a>' for ref in section.get('refs', []))
        sources = '<details class="sources"><summary>查看依據與原始規格</summary><div>' + refs + '</div></details>' if refs else ''
        chapters.append(f'<section class="chapter" id="{key}" data-status="{section["status"]}"><div class="chapter-label"><span>CHAPTER {index:02}</span><span class="badge {section["status"]}">{STATUS[section["status"]]}</span></div><h2>{title}</h2><p class="summary">{escape(section["summary"])}</p>{blocks}{sources}</section>')
    review = escape(content['review_note'])
    facts = ''.join(f'<div><strong>{escape(value)}</strong><span>{escape(label)}</span></div>' for value, label in content.get('facts', []))
    page = f'''<!doctype html>
<html lang="zh-Hant"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="description" content="Cyber Kingdom 現行遊戲企劃規格書：七星球探索、龍晶經濟、噬晶異獸、聚落 NPC 與版本相容規則。"><meta name="theme-color" content="#162625"><title>Cyber Kingdom — 遊戲企劃規格書</title><link rel="stylesheet" href="style.css"><script src="reader.js" defer></script></head>
<body><a class="skip" href="#document">跳到規格內容</a><aside class="sidebar"><a class="brand" href="#top"><span class="brand-mark" aria-hidden="true">✦</span><span>CYBER<br>KINGDOM<small>遊戲企劃規格書</small></span></a><p class="side-label">THE LAST REFUGE · DESIGN BOOK</p><nav aria-label="章節目錄">{''.join(nav)}</nav><div class="side-foot"><span class="status-dot"></span> v{version} · 修訂 {content['revision']}<a href="../">前往遊戲 ↗</a></div></aside>
<main id="document"><header id="top"><div class="topline"><span>最後的避難所 ／ 持續維護的設計文件</span><a href="../guide.html">玩家圖文指南 ↗</a></div><div class="hero"><p class="eyebrow">SEVEN WORLDS. ONE LAST REFUGE.</p><h1>讓遠方值得探索，<br>讓身後值得守護。</h1><p class="hero-copy">Cyber Kingdom 遊戲企劃規格書<br>從第一簇營火，到七顆古龍之核。</p><div class="hero-meta"><span>遊戲 v{version}</span><span>文件修訂 {content['revision']:02}</span><span>審訂 {content['updated']}</span></div><div class="hero-actions"><a class="primary" href="#loop">閱讀核心循環 <span>↘</span></a><a href="../">開啟遊戲 ↗</a></div><div class="orbits" aria-hidden="true"><span></span><span></span><span></span><i>✦</i></div></div><div class="facts">{facts}</div></header>
<div class="reader-tools"><label class="search-label" for="search">搜尋規格<input id="search" type="search" placeholder="試試：龍晶、NPC、存檔…" autocomplete="off"></label><label for="status-filter">範圍<select id="status-filter"><option value="all">所有章節</option><option value="current">現行實作</option><option value="legacy">相容／歷史</option><option value="pending">待驗證／決策</option></select></label><button id="print" type="button">列印／存 PDF</button></div><p id="search-status" class="search-status" aria-live="polite">共 {len(chapters)} 個章節 · 以目前新旅程為基準</p><noscript><p class="note">所有規格可直接閱讀；搜尋及列印按鈕需要 JavaScript，也可使用瀏覽器的列印功能。</p></noscript><div id="empty" hidden><h2>沒有符合的章節</h2><p>換個關鍵字，或重設閱讀範圍。</p><button id="reset" type="button">顯示所有章節</button></div>{''.join(chapters)}<footer><p>本次審訂：{review}</p><p>遊戲 v{version} · 文件修訂 {content['revision']} · {content['updated']}</p><a href="{REPO}/tree/{source_ref}/docs/game-spec">規格原始文件 ↗</a><a href="#top">回到頂端 ↑</a></footer></main></body></html>'''
    (output / 'index.html').write_text(page, encoding='utf-8')
    for name in ('style.css', 'reader.js'): shutil.copyfile(root / 'web/game-spec' / name, output / name)
    files = {p.relative_to(output).as_posix(): digest(p) for p in sorted(output.rglob('*')) if p.is_file()}
    manifest = {'schema': 1, 'game_version': version, 'revision': content['revision'], 'updated': content['updated'],
                'source_ref': source_ref, 'content_sha256': digest(root / CONTENT), 'files': files}
    (output / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    return manifest


def validate_bundle(output, tag):
    manifest = json.loads((output / 'manifest.json').read_text())
    if manifest['game_version'] != tag.removeprefix('v'): raise ValueError('Bundled specification version mismatch')
    if not {'index.html', 'reader.js', 'style.css'} <= manifest['files'].keys(): raise ValueError('Specification integrity: missing required file')
    for name, expected in manifest['files'].items():
        if digest(safe_source(output, name)) != expected: raise ValueError('Specification integrity mismatch: ' + name)


def publish_spec(root, site, tag, refresh=False, source_ref=None):
    """Preserve bundled release docs; only explicitly refresh a matching version.

    Build and validate before replacing spec/. No game-root files are written.
    """
    destination = site / 'spec'
    if destination.exists() and not refresh:
        validate_bundle(destination, tag)
        return
    with tempfile.TemporaryDirectory(prefix='cyber-spec-') as folder:
        staged = Path(folder) / 'spec'
        build(root, staged, tag, source_ref)
        validate_bundle(staged, tag)
        if destination.exists(): shutil.rmtree(destination)
        shutil.copytree(staged, destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument('--record-review', action='store_true')
    action.add_argument('--check', action='store_true')
    action.add_argument('--output', type=Path)
    action.add_argument('--publish-site', type=Path)
    parser.add_argument('--tag')
    parser.add_argument('--source-ref')
    parser.add_argument('--refresh', action='store_true')
    args = parser.parse_args()
    try:
        if args.record_review: record_review(args.root)
        elif args.check: validate_review(args.root)
        elif args.output: build(args.root, args.output, args.tag, args.source_ref)
        else:
            if not args.tag: parser.error('--publish-site requires --tag')
            publish_spec(args.root, args.publish_site, args.tag, args.refresh, args.source_ref)
    except (ValueError, KeyError, OSError) as error: parser.exit(1, str(error) + '\n')
    print('PASS: specification review/build')


if __name__ == '__main__': main()
