#!/usr/bin/env python3
"""Build an opt-in local diagnostic from a committed game, never a release artifact.

--scene audio compares the actual six-voice rack using Sample vs Stream.
--scene campaign runs the rendered forest for 32 real minutes at the phone's 30 Hz.
Serve OUTPUT/web on localhost; click Start to unlock sound. Read #soak-report.
Test-only actors are kept alive and periodic manual snapshots exercise restore.
Successful desktop testing is not an iPhone hardware stability guarantee.
"""
import argparse
from pathlib import Path
import shutil
import tempfile
from build_desktop import ROOT, prepare_tree, run_logged
from build_web import install_page_assets


def build(ref: str, output: Path, scene: str, godot: str) -> None:
    output.mkdir(parents=True, exist_ok=False)
    web = output / 'web'
    web.mkdir()
    with tempfile.TemporaryDirectory(prefix='cyber-soak-') as folder:
        stage = Path(folder)
        prepare_tree(ref, stage, 'demo')
        # Fixtures come from the working tools; the game itself is the requested commit.
        script = 'web_audio_probe.gd' if scene == 'audio' else 'web_campaign_soak.gd'
        shutil.copyfile(ROOT / 'tools' / script, stage / 'probe.gd')
        kind = 'Control' if scene == 'audio' else 'Node'
        (stage / 'probe.tscn').write_text(
            '[gd_scene load_steps=2 format=3]\n'
            '[ext_resource type="Script" path="res://probe.gd" id="1"]\n'
            f'[node name="Probe" type="{kind}"]\nscript = ExtResource("1")\n')
        project = stage / 'project.godot'
        project.write_text(project.read_text().replace(
            'run/main_scene="res://scenes/start_menu.tscn"',
            'run/main_scene="res://probe.tscn"'))
        if scene == 'campaign':
            profile = stage / 'data/web_performance.tres'
            profile.write_text(profile.read_text().replace('desktop_fps = 60', 'desktop_fps = 30'))
        engine = [godot, '--headless', '--path', str(stage)]
        run_logged(engine + ['--editor', '--import'], output / 'import.log')
        run_logged(engine + ['--export-release', 'Web Demo', str(web / 'index.html')], output / 'export.log')
        install_page_assets(stage, web)
    shutil.copyfile(ROOT / 'tools/web_audio_probe.js', web / 'audio-probe.js')
    html = web / 'index.html'
    html.write_text(html.read_text().replace('</head>', '<script src="audio-probe.js"></script></head>'))
    print(web)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ref', default='HEAD')
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--scene', choices=['audio', 'campaign'], default='campaign')
    parser.add_argument('--godot', default='/Applications/Godot.app/Contents/MacOS/Godot')
    args = parser.parse_args()
    build(args.ref, args.output.resolve(), args.scene, args.godot)
