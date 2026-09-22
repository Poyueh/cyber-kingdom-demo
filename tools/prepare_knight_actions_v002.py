"""Bake whole-body animation drawings on one native pixel grid. No runtime edits.

Sources and prompts live under art/concepts/knight-actions-v004 (.gdignore).
The user has authorised local alpha cleanup, slicing and pixel-density correction.
"""
from pathlib import Path
from collections import deque
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/concepts/knight-actions-v004/sources'
OUT = ROOT / 'art/characters/blacksteel-v002'
OUT.mkdir(exist_ok=True)
N = Image.Resampling.NEAREST
SOCKETS = {}


def clean(tile):
    a = np.array(tile.convert('RGBA'))
    mask = a[:, :, 3] >= 160
    seen = np.zeros(mask.shape, bool)
    parts = []
    for y, x in np.argwhere(mask):
        if seen[y, x]: continue
        queue = deque([(int(y), int(x))]); seen[y, x] = True; part = []
        while queue:
            cy, cx = queue.popleft(); part.append((cy, cx))
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                ny, nx = cy+dy, cx+dx
                if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True; queue.append((ny, nx))
        parts.append(part)
    a[:, :, 3] = 0
    largest = max(map(len, parts))
    for part in parts:
        if len(part) < max(5, largest*.015): continue
        for y, x in part: a[y, x, 3] = 255
    return Image.fromarray(a)


def tiles(name, columns, rows):
    sheet = Image.open(SOURCE / name).convert('RGBA')
    if isinstance(rows, int): rows = [round(i*sheet.height/rows) for i in range(rows+1)]
    result = []
    for y0, y1 in zip(rows, rows[1:]):
        for col in range(columns):
            result.append(clean(sheet.crop((round(col*sheet.width/columns), y0, round((col+1)*sheet.width/columns), y1))))
    return result


def native(tile, scale, size=(128, 96), ground=81, face_x=73, hop=0, align_face=True):
    bounds = tile.getbbox()
    a = np.array(tile)
    rgb = a[:, :, :3].astype(float)
    yy, xx = np.indices(a.shape[:2])
    # Visor, not a trailing blade. Limits select the upper part of a whole body.
    cyan = (rgb[:, :, 1] > rgb[:, :, 0]*1.3) & (rgb[:, :, 2] > rgb[:, :, 0]*1.4) & (a[:, :, 3] > 0)
    cyan &= (yy < bounds[1]+(bounds[3]-bounds[1])*.26)
    face = float(np.median(xx[cyan])) if cyan.any() else (bounds[0]+bounds[2])*.5
    resized = tile.resize((round(tile.width*scale), round(tile.height*scale)), N)
    result = Image.new('RGBA', size)
    dx = round(face_x-face*scale) if align_face else round(size[0]/2-(bounds[0]+bounds[2])*.5*scale)
    dy = round(ground-bounds[3]*scale-hop)
    result.alpha_composite(resized, (dx, dy))
    return result


def socket(frame, name='', mounted=False, resting=False, index=0):
    a=np.array(frame);rgb=a[:,:,:3].astype(float);yy,xx=np.indices(a.shape[:2])
    ground=frame.getbbox()[3]
    expected_x=frame.width*.57
    expected_y=ground-51
    if mounted:expected_y=ground-74
    elif resting or name.startswith('hurt') or name.startswith('death'):expected_y=frame.getbbox()[1]+9
    if name.startswith('death') and index==1:return (frame.getbbox()[2]-24,ground-6)
    mask=(a[:,:,3]>0)&(rgb[:,:,1]>rgb[:,:,0]*1.3)&(rgb[:,:,2]>rgb[:,:,0]*1.4)
    mask &= (abs(xx-expected_x)<18)&(abs(yy-expected_y)<13)
    if mask.any():
        ys,xs=np.where(mask)
        k=np.argmin((xs-expected_x)**2+(ys-expected_y)**2)
        return (int(xs[k])-9,int(ys[k])+8)
    return (round(expected_x)-9,round(expected_y)+8)


def pack(frames, columns, name, mounted=False, resting=False):
    w,h=frames[0].size
    atlas=Image.new('RGBA',(w*columns,h*((len(frames)+columns-1)//columns)))
    for i,frame in enumerate(frames):
        assert frame.getbbox(), (name,i,'empty frame')
        bounds=frame.getbbox()
        assert bounds[0]>0 and bounds[2]<w and bounds[1]>0 and bounds[3]<h, (name,i,'clipped native frame',bounds)
        atlas.alpha_composite(frame,(i%columns*w,i//columns*h))
    atlas.save(OUT/name)
    SOCKETS[name]=[socket(f,name,mounted,resting,i) for i,f in enumerate(frames)]
    return atlas


def embed(frame, ground=97):
    canvas=Image.new('RGBA',(160,128));canvas.alpha_composite(frame,(16,ground-81))
    return canvas


def sprint(frame):
    # Whole-body lean about the sole, without stretching or reassembling limbs.
    return frame.transform(frame.size,Image.Transform.AFFINE,(1,.09,-81*.09,0,1,0),resample=N)


run_raw=tiles('run.png',4,2)
run_unarmed_raw=tiles('run-unarmed.png',4,2)
scale=57/(run_raw[0].getbbox()[3]-run_raw[0].getbbox()[1])
run=[native(f,scale,hop=[0,0,1,3,0,0,1,3][i]) for i,f in enumerate(run_raw)]
unarmed=[native(f,scale,hop=[0,0,1,3,0,0,1,3][i]) for i,f in enumerate(run_unarmed_raw)]
pack(run,4,'run.png');pack(unarmed,4,'run-unarmed.png')
pack([sprint(f) for f in run],4,'sprint.png')
pack([sprint(f) for f in unarmed],4,'sprint-unarmed.png')

support=tiles('support.png',4,[0,331,626,876,1086])
bare=tiles('support-unarmed.png',4,[0,331,626,876,1086])
support_scale=60/(support[0].getbbox()[3]-support[0].getbbox()[1])
armed=[native(f,support_scale) for f in support]
bare=[native(f,support_scale) for f in bare]
for suffix,frames in [('',armed),('-unarmed',bare)]:
    pack(frames[:4],4,'idle'+suffix+'.png')
    # Full alternating low-stride walk uses the new complete gait at a slow cadence.
    pack(unarmed if suffix else run,4,'walk'+suffix+'.png')
    pack(frames[12:14],2,'hurt'+suffix+'.png')
    pack(frames[14:16],2,'death'+suffix+'.png')
pack([embed(f) for f in bare[8:12]+armed[8:12]],4,'rest.png',resting=True)

ceremony=tiles('ceremony-mount.png',4,[0,311,611,851,1122])
ceremony_scale=60/(ceremony[4].getbbox()[3]-ceremony[4].getbbox()[1])
pack([native(f,ceremony_scale,(160,128),97,89) for f in ceremony[:8]],4,'ceremony.png')
horse_scale=82/(ceremony[8].getbbox()[3]-ceremony[8].getbbox()[1])
pack([native(f,horse_scale,(160,128),97,89,align_face=False) for f in ceremony[8:]],8,'mounted.png',mounted=True)

combat=tiles('combat.png',4,[0,324,600,885,1170,1365,1536])
# Scale from body/boots, excluding a raised sword above the helmet.
combat_scales=[58/(combat[i].getbbox()[3]-combat[i].getbbox()[1]) for i in [2,8,18]]
planted=[native(f,combat_scales[i//8],(160,128),113,89,align_face=False) for i,f in enumerate(combat)]
pack(planted,8,'planted.png')
pack([f.transform(f.size,Image.Transform.AFFINE,(1,.06,-113*.06,0,1,0),resample=N) for f in planted],8,'advancing.png')

clips={'idle':('idle.png',4,4,4),'run':('run.png',8,4,12),'sprint':('sprint.png',8,4,16),
       'tired_walk':('walk.png',8,4,6),'attack':('run.png',8,4,12),'dash':('sprint.png',8,4,16),
       'jump':('run.png',4,4,12),'hurt':('hurt.png',2,2,8),'death':('death.png',2,2,4)}
files=list(dict.fromkeys(v[0] for v in clips.values()))
lines=['[gd_resource type="SpriteFrames" format=3]','']
for i,file in enumerate(files):lines.append(f'[ext_resource type="Texture2D" path="res://art/characters/blacksteel-v002/{file}" id="{i}"]')
animations=[]
for name,(file,count,columns,fps) in clips.items():
    refs=[]
    for i in range(count):
        key=f'{name}_{i}'
        lines.extend(['',f'[sub_resource type="AtlasTexture" id="{key}"]',f'atlas = ExtResource("{files.index(file)}")',f'region = Rect2({i%columns*128}, {i//columns*96}, 128, 96)','filter_clip = true'])
        refs.append('{"duration": 1.0, "texture": SubResource("'+key+'")}')
    loop='false' if name in ['hurt','death'] else 'true'
    animations.append('{"frames": ['+', '.join(refs)+f'], "loop": {loop}, "name": &"{name}", "speed": {fps}.0'+'}')
lines.extend(['','[resource]','animations = ['+',\n'.join(animations)+']'])
(ROOT/'data/blacksteel_v002_frames.tres').write_text('\n'.join(lines)+'\n')
(OUT/'sockets.json').write_text(json.dumps(SOCKETS,indent=2)+'\n')
appearance=['[gd_resource type="Resource" format=3]','',
 '[ext_resource type="Script" path="res://data/knight_appearance.gd" id="script"]',
 '[ext_resource type="SpriteFrames" path="res://data/blacksteel_v002_frames.tres" id="frames"]',
 '[ext_resource type="Resource" path="res://data/blacksteel_v002_combo.tres" id="combo"]']
textures={'unarmed_run':'run-unarmed.png','unarmed_idle':'idle-unarmed.png',
          'unarmed_sprint':'sprint-unarmed.png','unarmed_tired':'walk-unarmed.png',
          'unarmed_hurt':'hurt-unarmed.png','unarmed_death':'death-unarmed.png',
          'rest':'rest.png','ceremony':'ceremony.png','mounted':'mounted.png'}
for key,file in textures.items():appearance.append(f'[ext_resource type="Texture2D" path="res://art/characters/blacksteel-v002/{file}" id="{key}"]')
appearance.extend(['','[resource]','script = ExtResource("script")','frames = ExtResource("frames")','combo = ExtResource("combo")'])
for key in textures:appearance.append(f'{key} = ExtResource("{key}")')
appearance.extend(['idle_frames = 4','idle_columns = 4','sprint_fps = 16.0','tired_fps = 6.0','mounted_offset = Vector2(0, 0)','mounted_gait_frames = 4','mounted_attack_start = 4','module_sockets = {'])
appearance.extend('"'+name+'": ['+', '.join(f'Vector2({x}, {y})' for x,y in points)+'],' for name,points in SOCKETS.items())
appearance.extend(['}',''])
(ROOT/'data/blacksteel_v002_appearance.tres').write_text('\n'.join(appearance))
combo=(ROOT/'data/blacksteel_combo.tres').read_text().replace('blacksteel-v001','blacksteel-v002')
(ROOT/'data/blacksteel_v002_combo.tres').write_text(combo)
pack(run,4,'run-contact.png')
# Review animation is built from the exact native atlas frames.
frames=[]
for frame in run:
    bg=Image.new('RGBA',frame.size,'#172d37');bg.alpha_composite(frame)
    frames.append(bg.resize((512,384),N).convert('RGB'))
frames[0].save(OUT/'run-review.gif',save_all=True,append_images=frames[1:],duration=83,loop=0)
print('Prepared native action sheets and matching 8-frame run preview')
