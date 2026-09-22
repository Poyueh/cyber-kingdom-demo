#!/usr/bin/env python3
"""Export a committed game as a static, single-threaded browser build."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import sys
from build_desktop import prepare_tree, run_logged


def install_guide_reader(stage: Path, web: Path) -> None:
    for name in ('guide-reader.js', 'guide-reader.css'):
        shutil.copyfile(stage / 'web' / name, web / name)


def validate_export(web: Path) -> None:
    for name in ('index.html', 'index.js', 'index.wasm', 'index.pck'):
        path = web / name
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError('Missing or empty browser runtime file: ' + name)
    with (web / 'index.wasm').open('rb') as wasm:
        if wasm.read(8) != b'\x00asm\x01\x00\x00\x00':
            raise ValueError('Invalid WebAssembly runtime header')


def export_project(ref: str, output: Path, godot: str) -> Path:
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    web = output / 'web'
    web.mkdir()
    with tempfile.TemporaryDirectory(prefix='cyber-web-') as folder:
        stage = Path(folder)
        tree = prepare_tree(ref, stage)
        engine = [godot, '--headless', '--path', str(stage)]
        run_logged(engine + ['--editor', '--import'], output / 'import.log')
        run_logged(engine + ['--export-release', 'Web Demo', str(web / 'index.html')], output / 'export.log')
        run_logged([sys.executable, str(stage / 'tools/build_player_guide.py'), '--output', str(web / 'guide.html')], output / 'guide.log')
        install_guide_reader(stage, web)
        shutil.copyfile(stage / 'art/fonts/noto-sans-tc/OFL.txt', web / 'FONT-LICENSE.txt')
    validate_export(web)
    (web / 'README.txt').write_text(
        'Cyber Kingdom — 瀏覽器預覽版\n\n'
        '把此資料夾的全部檔案放在同一個網站目錄，再開啟 index.html 的網址。\n'
        '本機試玩：在此資料夾執行 python3 -m http.server 8780，開啟 http://localhost:8780。\n'
        '請勿使用 file:// 直接雙擊遊戲 HTML；引擎必須下載旁邊的 .wasm 與 .pck。\n'
        'guide.html 是可離線閱讀的玩家圖文指南。\n\n'
        '先點一下遊戲畫面，以便瀏覽器啟用聲音與鍵盤。\n'
        'A/D 移動；同方向雙按並按住衝刺；J／滑鼠左鍵連斬；E 互動；Q 丟晶；Esc 暫停。\n'
        '暫停選單可調整音量與手動存讀檔；書本圖示會在遊戲內開啟玩家圖文指南。\n'
        '閱讀時遊戲保持暫停，按 × 或 Esc 關閉指南，再按播放繼續。\n'
        '存檔保存在此網址對應的瀏覽器資料，與桌面版分開；清除網站資料會移除進度。\n'
        '需要支援 WebGL 2 與 WebAssembly 的瀏覽器，首次載入需下載遊戲資源。\n', encoding='utf-8')
    archive = Path(shutil.make_archive(str(output / 'Cyber-Kingdom-Web'), 'zip', web))
    (output / 'manifest.json').write_text(json.dumps({
        'source_tree': tree, 'entry': 'index.html', 'threads': False,
        'persistence': 'browser IndexedDB; separate per origin/profile',
        'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
        'files': {p.name: p.stat().st_size for p in web.iterdir() if p.is_file()},
        'browser_playtest': 'record separately; successful export is not a playtest'
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ref', default='HEAD')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--godot', default='/Applications/Godot.app/Contents/MacOS/Godot')
    args = parser.parse_args()
    print(export_project(args.ref, args.output, args.godot))
