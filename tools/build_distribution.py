"""Edition-specific staging. Source checkout and other release archives are untouched."""
import json, re, shutil
from pathlib import Path
LATER=("desert","frost","swamp","volcanic","storm","void")
def configure(stage: Path, edition=None):
 profile=stage/"distribution.json"
 edition=edition or (json.loads(profile.read_text())["edition"] if profile.exists() else "full")
 if edition not in ("full","demo"):raise ValueError("Unknown distribution edition")
 project=stage/"project.godot";s=project.read_text()
 s=re.sub(r'^config/name=.*$', 'config/name="Cyber Kingdom Forest Demo"' if edition=="demo" else 'config/name="Cyber Kingdom"',s,flags=re.M)
 s=re.sub(r'\n\[distribution\][^[]*','',s)
 # Preserve the historical main package's user directory. Demo gets its own directory.
 s=s.replace("[application]","[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="+json.dumps("Cyber Kingdom Forest Demo" if edition=="demo" else "Cyber Kingdom Demo"),1)
 s+='\n[distribution]\nedition='+json.dumps(edition)+'\n'
 project.write_text(s)
 presets=stage/"export_presets.cfg"
 if presets.exists():
  s=presets.read_text()
  s=s.replace("org.cyberkingdom.demo","org.cyberkingdom.forestdemo" if edition=="demo" else "org.cyberkingdom.game")
  s=s.replace('package/name="Cyber Kingdom Demo"','package/name="Cyber Kingdom Forest Demo"' if edition=="demo" else 'package/name="Cyber Kingdom"')
  s=s.replace('application/product_name="Cyber Kingdom Demo"','application/product_name="Cyber Kingdom Forest Demo"' if edition=="demo" else 'application/product_name="Cyber Kingdom"')
  presets.write_text(s)
 removed=[]
 if edition=="demo":
  for folder in ["data/planets","data/levels","data/trails","data/enemy_appearance","art/planets","art/characters/devourers-v001"]:
   for p in (stage/folder).rglob("*"):
    if p.is_file() and any(name in p.name for name in LATER):
     removed.append(p.relative_to(stage).as_posix());p.unlink()
  for catalog in ["planet_levels.tres","trail_encounters.tres"]:
   p=stage/"data"/catalog;s=p.read_text()
   ids=re.findall(r'^\[ext_resource[^\n]*path="[^"]*/(?:'+"|".join(LATER)+r')\.tres" id="([^"]+)"\]$',s,re.M)
   for id in ids:
    s=re.sub(r'^\[ext_resource[^\n]*id="'+re.escape(id)+r'"\]\n','',s,flags=re.M)
    s=s.replace(', ExtResource("'+id+'")','')
   p.write_text(s)
  p=stage/"data/enemy_cast.tres";s=p.read_text()
  for key,kind in [("guardians","elite"),("dragons","dragon")]:
   s=re.sub(r'^'+key+r' = .*$',key+' = Array[String](["res://data/enemy_appearance/'+kind+'-forest.tres"])',s,flags=re.M)
  p.write_text(s)
  p=stage/"bootstrap/frontier_root.gd";s=p.read_text()
  s=re.sub(r'^const PLANET_PROFILES=.*$','const PLANET_PROFILES=[preload("res://data/planets/forest.tres")]',s,flags=re.M);p.write_text(s)
  p=stage/"presentation/planet_scenery.gd";s=p.read_text()
  s=re.sub(r'^const (SKIES|TREE|ORE|SHRUB|LANDMARK|GROUND)=.*$',r'const \1: Array[Texture2D]=[]',s,flags=re.M);p.write_text(s)
  p=stage/"presentation/title_backdrop.gd";p.write_text(p.read_text().replace("art/planets/v002/void-sky.png","art/refuge/v001/skyline.png"))
  # Tests may preload intentionally excluded worlds. They never ship.
  shutil.rmtree(stage/"tests",ignore_errors=True)
 report={"edition":edition,"world_ids":[0] if edition=="demo" else list(range(7)),"removed_paths":sorted(removed),"shared_gameplay":"same committed source; only content and delivery identity differ"}
 (stage/"distribution-manifest.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
 return report
