#!/usr/bin/env python3
"""Preflight and export an Xcode project from Git. Signing/device installation remain separate."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from build_desktop import prepare_tree, run_logged

PRESET_NAME='iOS Demo'

def developer_environment(xcode=None):
    if xcode is None:
        selected=os.environ.get('DEVELOPER_DIR')
        if not selected:
            selected=subprocess.check_output(['xcode-select','-p'],text=True).strip()
        xcode=Path(selected)
    xcode=Path(xcode).expanduser().resolve()
    if xcode.suffix=='.app':xcode=xcode/'Contents/Developer'
    if not (xcode/'usr/bin/xcodebuild').is_file() or not (xcode/'Platforms/iPhoneOS.platform').is_dir():
        raise ValueError('需要完整 Xcode 與 iOS 平台；目前路徑不是可用的完整 Xcode：'+str(xcode))
    return dict(os.environ,DEVELOPER_DIR=str(xcode))

def validate_identifiers(team,bundle):
    if not team or not re.fullmatch(r'[A-Z0-9]{10}',team):
        raise ValueError('請提供你實際帳號的 10 碼 Team ID；不可用顯示名稱或留白。')
    if not bundle or not re.fullmatch(r'[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+',bundle):
        raise ValueError('請提供要使用的 Bundle ID（反向網域格式，不能含空白或底線）。')

def configured_preset(content,team,bundle):
    validate_identifiers(team,bundle)
    matches=list(re.finditer(r'^\[preset\.(\d+)\]\n(?:(?!^\[).)*?^name="iOS Demo"$',content,re.M|re.S))
    if len(matches)!=1:raise ValueError('預期只有一個 iOS Demo 匯出設定。')
    index=matches[0].group(1)
    options=re.search(r'^\[preset\.'+index+r'\.options\]\n([^\[]*)',content,re.M)
    if options is None:raise ValueError('缺少 iOS 匯出選項。')
    updated=options.group(0)
    for key,value in {'application/app_store_team_id':team,'application/bundle_identifier':bundle}.items():
        updated,count=re.subn(r'^'+re.escape(key)+r'=.*$',key+'='+json.dumps(value),updated,flags=re.M)
        if count!=1:raise ValueError('缺少或重複的 iOS 欄位：'+key)
    if 'application/export_project_only=true' not in updated:
        raise ValueError('此工具只匯出 Xcode 專案；請保留 export_project_only=true。')
    return content[:options.start()]+updated+content[options.end():]

def probe(args,env=None):
    result=subprocess.run(args,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
    if result.returncode:raise ValueError(result.stdout.strip() or '指令失敗：'+args[0])
    return result.stdout.strip()

def preflight(godot,xcode=None,team=None,bundle=None):
    report={'ready_for_export':False,'installable':False,'issues':[]}
    env=None
    try:
        version=probe([str(godot),'--version'])
        report['godot']=version
        template_version='.'.join(version.split('.')[:4])
        template=Path.home()/'Library/Application Support/Godot/export_templates'/template_version/'ios.zip'
        report['ios_template']=str(template)
        if not template.is_file():report['issues'].append('缺少與 Godot 相同版本的 ios.zip 匯出模板。')
    except (ValueError,OSError,subprocess.SubprocessError) as exc:report['issues'].append(str(exc))
    try:
        env=developer_environment(xcode)
        report['developer_dir']=env['DEVELOPER_DIR']
        report['xcode']=probe(['xcodebuild','-version'],env)
        sdk=probe(['xcrun','--sdk','iphoneos','--show-sdk-path'],env)
        if not Path(sdk).is_dir():raise ValueError('Xcode 回報的 iPhoneOS SDK 不存在。')
        report['iphoneos_sdk']=sdk
    except (ValueError,OSError,subprocess.SubprocessError) as exc:report['issues'].append(str(exc))
    try:validate_identifiers(team,bundle)
    except ValueError as exc:report['issues'].append(str(exc))
    report['ready_for_export']=not report['issues']
    return report,env

def validate_export(output):
    project=output/'CyberKingdomDemo.xcodeproj/project.pbxproj'
    packs=list(output.rglob('*.pck'))
    if not project.is_file() or not packs or any(p.stat().st_size==0 for p in packs):
        raise ValueError('匯出未產生完整 Xcode 專案與遊戲 PCK；不可當成成功。')
    return project.parent

def export_project(ref,output,team,bundle,godot,env,edition=None):
    validate_identifiers(team,bundle)
    # Refuse to reuse any destination; the engine must not erase a previous export.
    output=Path(output).resolve()
    if output.exists():raise ValueError('輸出目錄已存在，請選新的目錄：'+str(output))
    with tempfile.TemporaryDirectory(prefix='cyber-ios-') as folder:
        stage=Path(folder)
        tree=prepare_tree(ref,stage,edition)
        preset=stage/'export_presets.cfg'
        preset.write_text(configured_preset(preset.read_text(),team,bundle))
        output.mkdir(parents=True)
        (output/"distribution-manifest.json").write_bytes((stage/"distribution-manifest.json").read_bytes())
        # A subprocess-local developer directory never changes xcode-select or other builds.
        run_logged([str(godot),'--headless','--path',str(stage),'--editor','--import'],output/'import.log',env=env)
        run_logged([str(godot),'--headless','--path',str(stage),'--export-debug',PRESET_NAME,str(output/'CyberKingdomDemo.zip')],output/'export.log',env=env)
    project=validate_export(output)
    (output/'manifest.json').write_text(json.dumps({'source_tree':tree,'xcode_project':project.name,'bundle_id':bundle,'export':'Xcode project only','installable':False,'signing':'Pending Xcode build and real device deployment','device_playtest':'not performed'},indent=2)+'\n')
    return project

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true',help='Read-only preflight; never creates an export')
    parser.add_argument('--ref',default='HEAD')
    parser.add_argument('--output',type=Path)
    parser.add_argument('--team-id')
    parser.add_argument('--bundle-id')
    parser.add_argument('--xcode',type=Path,help='Xcode.app or its Contents/Developer; leaves global selection unchanged')
    parser.add_argument('--godot',type=Path,default=Path('/Applications/Godot.app/Contents/MacOS/Godot'))
    parser.add_argument("--edition",choices=["full","demo"])
    args=parser.parse_args()
    report,env=preflight(args.godot,args.xcode,args.team_id,args.bundle_id)
    if args.check or not report['ready_for_export']:
        print(json.dumps(report,ensure_ascii=False,indent=2))
        return 0 if report['ready_for_export'] else 2
    if args.output is None:parser.error('匯出需要 --output 指定新的目錄。')
    try:project=export_project(args.ref,args.output,args.team_id,args.bundle_id,args.godot,env,args.edition)
    except (ValueError,RuntimeError,OSError,subprocess.SubprocessError) as exc:
        parser.exit(1,str(exc)+'\n')
    print('Xcode 專案已產生（尚未簽署或安裝）：'+str(project))
    return 0
if __name__=='__main__':raise SystemExit(main())
