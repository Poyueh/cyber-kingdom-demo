from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
OUT='res://art/characters/hero-v009/'
GAIT='res://art/characters/hero-v009/'
def atlas_path(file): return (GAIT if file.startswith('gait-') else OUT)+file+'.png'
clips={'idle':('idle',4,4,3),'run':('gait-walk',8,4,14),'sprint':('gait-sprint',8,4,18),'tired_walk':('gait-walk',8,4,8),'attack':('idle',4,4,12),'dash':('gait-sprint',8,4,18),'jump':('jump',4,4,12),'hurt':('hurt',4,4,12),'death':('death',4,4,6)}
files=list(dict.fromkeys(x[0] for x in clips.values()))
lines=['[gd_resource type="SpriteFrames" format=3]','']
for i,file in enumerate(files):lines.append(f'[ext_resource type="Texture2D" path="{atlas_path(file)}" id="{i}"]')
animations=[]
for name,(file,count,columns,fps) in clips.items():
 refs=[]
 for i in range(count):
  key=f'{name}_{i}'
  lines.extend(['',f'[sub_resource type="AtlasTexture" id="{key}"]',f'atlas = ExtResource("{files.index(file)}")',f'region = Rect2({i%columns*128}, {i//columns*96}, 128, 96)','filter_clip = true'])
  refs.append('{"duration": 1.0, "texture": SubResource("'+key+'")}')
 animations.append('{"frames": ['+', '.join(refs)+f'], "loop": {"false" if name in ("hurt","death") else "true"}, "name": &"{name}", "speed": {fps}.0'+'}')
lines.extend(['','[resource]','animations = ['+',\n'.join(animations)+']'])
(ROOT/'data/hero_v005_frames.tres').write_text('\n'.join(lines)+'\n')
lines=['[gd_resource type="Resource" format=3]','',
'[ext_resource type="Script" path="res://data/combo_motion.gd" id="script"]',
f'[ext_resource type="Texture2D" path="{OUT}planted.png" id="planted"]',
f'[ext_resource type="Texture2D" path="{OUT}advancing.png" id="advancing"]','',
'[resource]','script = ExtResource("script")','planted_atlas = ExtResource("planted")','moving_atlas = ExtResource("advancing")','moving_gait_rows = 1',
'slash_weights = PackedFloat32Array(0.05, 0.08, 0.11, 0.16, 0.06, 0.065, 0.12, 0.105, 0.09, 0.06, 0.05, 0.05)',
'rising_weights = PackedFloat32Array(0.04, 0.05, 0.06, 0.10, 0.07, 0.085, 0.11, 0.135, 0.11, 0.10, 0.08, 0.06)',
'heavy_weights = PackedFloat32Array(0.04, 0.06, 0.08, 0.15, 0.07, 0.08, 0.13, 0.14, 0.09, 0.06, 0.05, 0.05)']
(ROOT/'data/hero_v005_combo.tres').write_text('\n'.join(lines)+'\n')
textures={'unarmed_run':'gait-walk-unarmed','unarmed_idle':'idle-unarmed','unarmed_sprint':'gait-sprint-unarmed','unarmed_tired':'gait-walk-unarmed','unarmed_hurt':'hurt-unarmed','unarmed_death':'death-unarmed','unarmed_jump':'jump-unarmed','rest':'rest','ceremony':'ceremony','mounted':'mounted','unarmed_mounted':'mounted-unarmed'}
lines=['[gd_resource type="Resource" format=3]','',
'[ext_resource type="Script" path="res://data/knight_appearance.gd" id="script"]',
'[ext_resource type="SpriteFrames" path="res://data/hero_v005_frames.tres" id="frames"]',
'[ext_resource type="Resource" path="res://data/hero_v005_combo.tres" id="combo"]']
for key,file in textures.items():lines.append(f'[ext_resource type="Texture2D" path="{atlas_path(file)}" id="{key}"]')
lines+=['','[resource]','script = ExtResource("script")','frames = ExtResource("frames")','combo = ExtResource("combo")']
for key in textures:lines.append(f'{key} = ExtResource("{key}")')
lines+=['idle_frames = 4','idle_columns = 4','stride_frames = 8','stride_columns = 4','run_fps = 14.0','sprint_fps = 18.0','tired_fps = 8.0','run_reference_speed = 165.0','sprint_reference_speed = 321.75','tired_reference_speed = 69.3','reaction_frames = 4','mounted_offset = Vector2(0, 0)','mounted_gait_frames = 8','mounted_attack_start = 8','mounted_attack_frames = 4','mounted_idle_start = 12','mounted_idle_frames = 2','mounted_hurt_frame = 14','mounted_rest_frame = 15','rest_transition_frames = true','module_sockets = {']
sockets=json.loads((ROOT/'art/characters/hero-v009/sockets.json').read_text())
for name,points in sockets.items():
 lines.append('"'+name+'": ['+', '.join(f'Vector2({p[0]}, {p[1]})' for p in points)+'],')
lines.append('}')
(ROOT/'data/hero_v005_appearance.tres').write_text('\n'.join(lines)+'\n')
print('Built hero resources')
