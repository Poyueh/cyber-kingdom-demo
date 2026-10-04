"""Rebuild v003 full-body drawings at native game density (Pillow + NumPy).

Sources/prompts: art/concepts/knight-actions-v005, excluded from export.
Authorised offline alpha cleanup, component-aware slicing and nearest scaling.
No affine limb/body edits; every gait and advancing strike is independently drawn.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/concepts/knight-actions-v005/sources'
OUT = ROOT / 'art/characters/blacksteel-v003'
REVIEW = ROOT / 'docs/reports/knight-v003'
OUT.mkdir(exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
N = Image.Resampling.NEAREST
SOCKETS = {}
METRICS = {}

def components(mask):
 parents=[]; spans=[]; previous=[]
 def root(i):
  while parents[i]!=i:
   parents[i]=parents[parents[i]]; i=parents[i]
  return i
 for y,row in enumerate(mask):
  edges=np.diff(np.pad(row.astype(np.int8),(1,1)))
  starts=np.flatnonzero(edges==1);ends=np.flatnonzero(edges==-1)
  current=[]; k=0
  for left,right in zip(starts,ends):
   i=len(parents); parents.append(i)
   while k<len(previous) and previous[k][1]<left:k+=1
   j=k
   while j<len(previous) and previous[j][0]<=right:
    parents[root(previous[j][2])]=root(i); j+=1
   current.append((int(left),int(right),i)); spans.append((y,int(left),int(right),i))
  previous=current
 groups={}
 for y,l,r,i in spans:groups.setdefault(root(i),[]).append((y,l,r))
 return sorted(groups.values(),key=lambda a:sum(r-l for _,l,r in a),reverse=True)


def tiles(name, count, rows):
    """Separate complete connected drawings, not arbitrary grid boundaries.

    Weapon tips may cross the nominal cell edge; isolating the figure preserves
    those tips without borrowing pixels from an adjacent pose.
    """
    image = Image.open(SOURCE / name).convert('RGBA')
    a = np.array(image)
    parts = components(a[:, :, 3] >= 160)
    major = parts[:count]
    def bounds(part):
        return (min(l for _,l,_ in part), min(y for y,_,_ in part),
                max(r for _,_,r in part), max(y for y,_,_ in part)+1)
    # Rows are ordered by feet; raised swords do not change temporal order.
    major.sort(key=lambda p: bounds(p)[3])
    ordered = []
    for row in range(rows):
        ordered += sorted(major[row*4:(row+1)*4], key=lambda p: bounds(p)[0])
    # The buried sword in ceremony frame 0 is deliberately disconnected.
    if name == 'ceremony.png':
        ordered[0] = ordered[0] + parts[count]
    result = []
    for part in ordered:
        box = bounds(part)
        tile = np.zeros((box[3]-box[1], box[2]-box[0], 4), dtype=np.uint8)
        for y,l,r in part:
            tile[y-box[1],l-box[0]:r-box[0]] = a[y,l:r]
            tile[y-box[1],l-box[0]:r-box[0],3] = 255
        result.append(Image.fromarray(tile))
    assert len(result) == count
    return result


def native(tile, scale, size=(128,96), ground=81, hop=0, anchor='face'):
    a = np.array(tile)
    rgb = a[:,:,:3].astype(float)
    yy,xx = np.indices(a.shape[:2])
    solid = a[:,:,3]>0
    cyan = (rgb[:,:,1]>rgb[:,:,0]*1.3)&(rgb[:,:,2]>rgb[:,:,0]*1.4)&solid
    if anchor == 'face':
        mask = cyan & (yy<tile.height*.27)
        source_x = float(np.median(xx[mask])) if mask.any() else tile.width*.6
        target_x = size[0]/2+9
    else:
        # Grounded armor, excluding red cape and cyan blade, anchors the pelvis.
        neutral = (rgb[:,:,1]>rgb[:,:,0]*.78)&(rgb[:,:,1]<rgb[:,:,0]*1.25)&(rgb[:,:,2]<rgb[:,:,0]*1.4)
        mask = solid & neutral & (yy>tile.height*.72)
        source_x = float(np.median(xx[mask])) if mask.any() else tile.width*.5
        target_x = size[0]/2
    resized=tile.resize((round(tile.width*scale),round(tile.height*scale)),N)
    result=Image.new('RGBA',size)
    dx=round(target_x-source_x*scale)
    dy=ground-resized.height-hop
    assert dx>=1 and dx+resized.width<size[0] and dy>=1, (size,dx,dy,resized.size)
    result.alpha_composite(resized,(dx,dy))
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
    METRICS[name] = {'frames': len(frames), 'cell': [w,h], 'columns': columns, 'bounds': [list(f.getbbox()) for f in frames]}
    SOCKETS[name]=[socket(f,name,mounted,resting,i) for i,f in enumerate(frames)]
    return atlas


def embed(frame, ground=97):
    canvas=Image.new('RGBA',(160,128));canvas.alpha_composite(frame,(16,ground-81))
    return canvas



review_clips = {}
for action, height, fps in [('run',57,18),('sprint',55,24),('walk',60,10)]:
    raw=tiles(action+'.png',12,3)
    scale=height/float(np.median([f.height for f in raw]))
    for suffix in ['', '-unarmed']:
        drawings=raw if not suffix else tiles(action+suffix+'.png',12,3)
        hops=[0,0,1,2,2,1,0,0,1,2,2,1] if action!='walk' else [0]*12
        frames=[native(f,scale,hop=hops[i]) for i,f in enumerate(drawings)]
        pack(frames,4,action+suffix+'.png')
        review_clips[action+suffix]=(frames,[round(1000/fps)]*12)

support=tiles('support.png',12,3)
bare=tiles('support-unarmed.png',12,3)
scale=60/float(np.median([f.height for f in support[:4]]))
armed=[native(f,scale,anchor='feet' if i>=4 else 'face') for i,f in enumerate(support)]
unarmed=[native(f,scale,anchor='feet' if i>=4 else 'face') for i,f in enumerate(bare)]
for suffix,frames in [('',armed),('-unarmed',unarmed)]:
    pack(frames[:4],4,'idle'+suffix+'.png')
    pack(frames[8:10],2,'hurt'+suffix+'.png')
    pack(frames[10:12],2,'death'+suffix+'.png')
    review_clips['idle'+suffix]=(frames[:4],[250]*4)
pack([embed(f) for f in unarmed[4:8]+armed[4:8]],4,'rest.png',resting=True)

ceremony=tiles('ceremony.png',8,2)
scale=60/ceremony[0].height
pack([native(f,scale,(160,128),97,anchor='feet') for f in ceremony],4,'ceremony.png')
horse=tiles('mounted.png',8,2)
scale=82/horse[0].height
pack([native(f,scale,(160,128),97,hop=3 if i==2 else 0,anchor='feet') for i,f in enumerate(horse)],8,'mounted.png',mounted=True)

WEIGHTS = [
    [.08,.08,.24,.07,.15,.13,.13,.12],
    [.06,.06,.13,.07,.19,.14,.13,.22],
    [.055,.065,.28,.07,.21,.07,.12,.13],
]
for suffix,atlas in [('', 'planted.png'),('-advance','advancing.png')]:
    frames=[]
    for step,clip in enumerate(['slash','rising','heavy']):
        raw=tiles(clip+suffix+'.png',8,2)
        scale=60/raw[0].height
        native_frames=[native(f,scale,(160,128),113,anchor='feet') for f in raw]
        frames.extend(native_frames)
        review_clips[clip+suffix]=(native_frames,[round(v*650) for v in WEIGHTS[step]])
    pack(frames,8,atlas)

clips={'idle':('idle.png',4,4,4),'run':('run.png',12,4,18),'sprint':('sprint.png',12,4,24),
       'tired_walk':('walk.png',12,4,10),'attack':('run.png',12,4,18),'dash':('sprint.png',12,4,24),
       'jump':('run.png',4,4,12),'hurt':('hurt.png',2,2,8),'death':('death.png',2,2,4)}
files=list(dict.fromkeys(v[0] for v in clips.values()))
lines=['[gd_resource type="SpriteFrames" format=3]','']
for i,file in enumerate(files):lines.append(f'[ext_resource type="Texture2D" path="res://art/characters/blacksteel-v003/{file}" id="{i}"]')
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
(ROOT/'data/blacksteel_v003_frames.tres').write_text('\n'.join(lines)+'\n')
(OUT/'sockets.json').write_text(json.dumps(SOCKETS,indent=2)+'\n')
appearance=['[gd_resource type="Resource" format=3]','',
 '[ext_resource type="Script" path="res://data/knight_appearance.gd" id="script"]',
 '[ext_resource type="SpriteFrames" path="res://data/blacksteel_v003_frames.tres" id="frames"]',
 '[ext_resource type="Resource" path="res://data/blacksteel_v003_combo.tres" id="combo"]']
textures={'unarmed_run':'run-unarmed.png','unarmed_idle':'idle-unarmed.png',
          'unarmed_sprint':'sprint-unarmed.png','unarmed_tired':'walk-unarmed.png',
          'unarmed_hurt':'hurt-unarmed.png','unarmed_death':'death-unarmed.png',
          'rest':'rest.png','ceremony':'ceremony.png','mounted':'mounted.png'}
for key,file in textures.items():appearance.append(f'[ext_resource type="Texture2D" path="res://art/characters/blacksteel-v003/{file}" id="{key}"]')
appearance.extend(['','[resource]','script = ExtResource("script")','frames = ExtResource("frames")','combo = ExtResource("combo")'])
for key in textures:appearance.append(f'{key} = ExtResource("{key}")')
appearance.extend(['idle_frames = 4','idle_columns = 4','stride_frames = 12','stride_columns = 4','run_fps = 18.0','sprint_fps = 24.0','tired_fps = 10.0','mounted_offset = Vector2(0, 0)','mounted_gait_frames = 4','mounted_attack_start = 4','module_sockets = {'])
appearance.extend('"'+name+'": ['+', '.join(f'Vector2({x}, {y})' for x,y in points)+'],' for name,points in SOCKETS.items())
appearance.extend(['}',''])
(ROOT/'data/blacksteel_v003_appearance.tres').write_text('\n'.join(appearance))
combo=(ROOT/'data/blacksteel_combo.tres').read_text().replace('blacksteel-v001','blacksteel-v003')
for key,weights in zip(['slash','rising','heavy'], WEIGHTS):
    import re
    combo=re.sub(key+r'_weights = PackedFloat32Array\([^)]*\)',key+'_weights = PackedFloat32Array('+', '.join(map(str,weights))+')',combo)
(ROOT/'data/blacksteel_v003_combo.tres').write_text(combo)

# Both review scales use exactly the exported pixels, never the raw sources.
for name,(frames,durations) in review_clips.items():
    review=[]
    for frame in frames:
        bg=Image.new('RGBA',frame.size,'#172d37')
        bg.alpha_composite(frame)
        review.append(bg.resize((frame.width*4,frame.height*4),N).convert('RGB'))
    review[0].save(REVIEW/(name+'.gif'),save_all=True,append_images=review[1:],duration=durations,loop=0,disposal=2)
    contact=Image.new('RGB',(frames[0].width*4,frames[0].height*((len(frames)+3)//4)), '#172d37')
    for i,f in enumerate(frames):contact.paste(f,(i%4*f.width,i//4*f.height),f)
    contact.resize((contact.width*2,contact.height*2),N).save(REVIEW/(name+'-contact.png'))
(REVIEW/'atlas-checks.json').write_text(json.dumps(METRICS,indent=2)+'\n')
print('Prepared v003 native atlases, appearance resources, sockets and same-source review clips.')
