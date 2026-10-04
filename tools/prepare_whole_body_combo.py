"""Prepare authored whole-body combos; no limb transforms or invented frames.

Pillow + NumPy. Shared scale per clip. Boot-contact midpoint anchors the stance;
pelvis/helmet/cape motion is preserved instead of recentering the body per frame.
Raw sources and exact prompts remain in art/concepts/knight-combo-v004.
"""
from pathlib import Path
import json,re
import numpy as np
from PIL import Image,ImageDraw
from sprite_components import components

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art/concepts/knight-combo-v004/sources'
OUT=ROOT/'art/characters/blacksteel-combo-v004'
REVIEW=ROOT/'docs/reports/whole-body-combo'
N=Image.Resampling.NEAREST
CELL=(160,128)
GROUND=113
WEIGHTS=[[.09,.13,.18,.10,.15,.13,.12,.10],
         [.08,.08,.09,.15,.15,.10,.13,.22],
         [.065,.095,.24,.105,.175,.11,.11,.10]]
DURATIONS=[.34,.34*.82,.34*1.25]


def bounds(part):
    return (min(l for _,l,_ in part),min(y for y,_,_ in part),
            max(r for _,_,r in part),max(y for y,_,_ in part)+1)


def drawings(name):
    a=np.array(Image.open(SOURCE/(name+'.png')).convert('RGBA'))
    parts=components(a[:,:,3]>=160)
    assert len(parts)>=8,(name,len(parts))
    major=parts[:8]
    major.sort(key=lambda p:bounds(p)[3])
    ordered=sorted(major[:4],key=lambda p:bounds(p)[0])+sorted(major[4:],key=lambda p:bounds(p)[0])
    result=[]
    for part in ordered:
        x,y,right,bottom=bounds(part)
        tile=np.zeros((bottom-y,right-x,4),dtype=np.uint8)
        for row,left,end in part:
            tile[row-y,left-x:end-x]=a[row,left:end]
            tile[row-y,left-x:end-x,3]=255
        result.append(Image.fromarray(tile))
    return result


def native(tile,scale):
    a=np.array(tile);rgb=a[:,:,:3].astype(float);yy,xx=np.indices(a.shape[:2])
    solid=a[:,:,3]>0
    # Only soles, never the pelvis or knee. Weight transfer must remain visible.
    neutral=(rgb[:,:,1]>rgb[:,:,0]*.7)&(rgb[:,:,1]<rgb[:,:,0]*1.35)&(rgb[:,:,2]<rgb[:,:,0]*1.5)
    soles=solid & neutral & (yy>=tile.height-max(4,round(tile.height*.025)))
    xs=xx[soles]
    assert len(xs)>0
    pivot=(xs.min()+xs.max())/2
    scaled=tile.resize((round(tile.width*scale),round(tile.height*scale)),N)
    dx=round(CELL[0]/2-pivot*scale);dy=GROUND-scaled.height
    assert dx>0 and dy>0 and dx+scaled.width<CELL[0],(dx,dy,scaled.size)
    frame=Image.new('RGBA',CELL);frame.alpha_composite(scaled,(dx,dy))
    return frame


def main():
    OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    metadata={};sockets={}
    attachments=json.loads((SOURCE.parent/"attachments.json").read_text())
    for suffix,atlas_name in [('', 'planted.png'),('-advance','advancing.png')]:
        atlas=Image.new('RGBA',(CELL[0]*8,CELL[1]*3));points=[]
        for step,action in enumerate(['slash','rising','heavy']):
            name=action+suffix;raw=drawings(name)
            scale=60/raw[0].height
            frames=[native(frame,scale) for frame in raw]
            measurements=[]
            for i,frame in enumerate(frames):
                atlas.alpha_composite(frame,(i*CELL[0],step*CELL[1]))
                socket=attachments[name][i];points.append(socket)
                measurements.append({'bounds':frame.getbbox(),'socket':socket})
            metadata[name]={'scale':scale,'frames':measurements}
            contact=Image.new('RGBA',(CELL[0]*4,CELL[1]*2),'#172d37')
            previews=[]
            for i,frame in enumerate(frames):
                contact.alpha_composite(frame,(i%4*CELL[0],i//4*CELL[1]))
                preview=Image.new('RGBA',CELL,'#172d37');preview.alpha_composite(frame)
                previews.append(preview.resize((640,512),N).convert('RGB'))
            contact.resize((1280,512),N).save(REVIEW/(name+'-contact.png'))
            previews[0].save(REVIEW/(name+'.webp'),save_all=True,append_images=previews[1:],duration=[max(16,round(w*DURATIONS[step]*1000)) for w in WEIGHTS[step]],loop=0,lossless=True)
        atlas.save(OUT/atlas_name);sockets[atlas_name]=points
    appearance=(ROOT/'data/blacksteel_v003_appearance.tres').read_text().replace('blacksteel_v003_combo.tres','blacksteel_v004_combo.tres')
    for name,points in sockets.items():
        appearance=re.sub(r'"'+re.escape(name)+r'": \[[^\n]*', '"'+name+'": ['+', '.join(f'Vector2({x}, {y})' for x,y in points)+'],',appearance)
    (ROOT/'data/blacksteel_v004_appearance.tres').write_text(appearance)
    combo=(ROOT/'data/blacksteel_v003_combo.tres').read_text().replace('characters/blacksteel-v003','characters/blacksteel-combo-v004')
    for name,weights in zip(['slash','rising','heavy'],WEIGHTS):
        combo=re.sub(name+r'_weights = PackedFloat32Array\([^)]*\)',name+'_weights = PackedFloat32Array('+', '.join(map(str,weights))+')',combo)
    (ROOT/'data/blacksteel_v004_combo.tres').write_text(combo)
    (REVIEW/'atlas-checks.json').write_text(json.dumps(metadata,indent=2)+'\n')
    print('Prepared 48 whole-body frames and v004 combo / appearance resources.')

if __name__=='__main__':main()
