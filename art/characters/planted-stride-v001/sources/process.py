from pathlib import Path
import math,json
from PIL import Image,ImageDraw
import numpy as np
# Offline atlas generation only; no image processing runs inside the game.
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent.parent
OUT.mkdir(exist_ok=True);(OUT/'sources').mkdir(exist_ok=True);(OUT/'sources/.gdignore').touch()
N=16;CELL=(128,96)
def segment(d,a,b,w,front):
 dx,dy=b[0]-a[0],b[1]-a[1];L=max(1,math.hypot(dx,dy));nx,ny=-dy/L,dx/L
 def poly(width,trim=0):
  return [(round(a[0]+nx*width/2+dx/L*trim),round(a[1]+ny*width/2+dy/L*trim)),(round(b[0]+nx*width/2-dx/L*trim),round(b[1]+ny*width/2-dy/L*trim)),(round(b[0]-nx*width/2-dx/L*trim),round(b[1]-ny*width/2-dy/L*trim)),(round(a[0]-nx*width/2+dx/L*trim),round(a[1]-ny*width/2+dy/L*trim))]
 d.polygon(poly(w+2),fill='#1c2023');d.polygon(poly(w),fill='#805116' if front else '#493815')
 d.polygon(poly(w-2,1),fill='#cc901e' if front else '#826019')
 d.line((round(a[0]-nx),round(a[1]-ny),round(b[0]-nx),round(b[1]-ny)),fill='#f6d364' if front else '#b48a37',width=1)
 # Exposed piston and armor seam.
 t=.6;p=(a[0]+dx*t,a[1]+dy*t)
 d.line((round(p[0]-nx*w/2),round(p[1]-ny*w/2),round(p[0]+nx*w/2),round(p[1]+ny*w/2)),fill='#493713',width=1)
def leg(im,hip,foot,front,lift):
 d=ImageDraw.Draw(im);dx,dy=foot[0]-hip[0],foot[1]-hip[1];dist=math.hypot(dx,dy);bend=math.sqrt(max(0,15**2-(dist*.5)**2));knee=((hip[0]+foot[0])*.5+dy/dist*bend,(hip[1]+foot[1])*.5-dx/dist*bend)
 segment(d,hip,knee,7,front);segment(d,knee,foot,5,front)
 x,y=map(round,knee);d.ellipse((x-3,y-3,x+3,y+3),fill='#302a1a');d.ellipse((x-2,y-2,x+2,y+2),fill='#bb871f' if front else '#705119');d.point((x-1,y-1),fill='#fff1a0' if front else '#bf9443');d.point((x+1,y),fill='#8de5d4' if front else '#537b72')
 x,y=map(round,foot);toe=2 if lift>7 else 0
 d.polygon([(x-3,y-3),(x+2,y-3),(x+3,y),(x+8,y+toe),(x+8,y+3+toe),(x-3,y+3)],fill='#1c2023')
 d.polygon([(x-2,y-2),(x+1,y-2),(x+2,y+1),(x+6,y+1+toe),(x+6,y+2+toe),(x-2,y+2)],fill='#bd8b25' if front else '#756025');d.line((x-1,y,x+2,y+1),fill='#ffe477' if front else '#b5964b')
 return {'hip':hip,'knee':knee,'ankle':foot,'front':front,'lift':lift}
meta=[]
for armed in (False,True):
 source=Image.open(ROOT/('art/characters/stride-v001/armed.png' if armed else 'art/characters/stride-v001/unarmed.png')).convert('RGBA').crop((0,0,128,96))
 a=np.array(source);body=a.copy();body[60:,:,3]=0
 # Retain silver blade below the belt, but never any of the old golden legs.
 if armed:
  blade=Image.new('L',CELL);ImageDraw.Draw(blade).polygon([(14,67),(57,49),(60,54),(18,71)],fill=255)
  keep=(np.array(blade)>0)&(np.indices(a.shape[:2])[0]>=60)
  body[keep]=a[keep]
 yy,xx=np.indices(body.shape[:2]);rgb=body[:,:,:3].astype(int)
 cape_mask=(body[:,:,3]>0)&(xx<57)&(rgb[:,:,0]>rgb[:,:,1]*1.4)&(rgb[:,:,0]>rgb[:,:,2]*1.25)
 expanded=cape_mask.copy()
 for dy in [-1,0,1]:
  for dx in [-1,0,1]:expanded|=np.roll(np.roll(cape_mask,dy,0),dx,1)
 expanded&=(xx<57)
 cape=body.copy();cape[:,:,3]=np.where(expanded,body[:,:,3],0);body[expanded,3]=0
 cape=Image.fromarray(cape);upper=Image.fromarray(body);atlas=Image.new('RGBA',(128*8,96*2));frames=[]
 for i in range(N):
  phase=i/N;bob=round(math.sin(phase*4*math.pi))
  im=Image.new('RGBA',CELL);hip=(61,57+bob);points=[]
  for front,off in [(False,.5),(True,0)]:
   p=(phase+off)%1
   if p<.5:foot=(61+19-76*p,77);lift=0
   else:
    t=(p-.5)*2;lift=15*math.sin(math.pi*t);foot=(42+38*t,77-lift)
   points.append(leg(im,hip,foot,front,lift))
  # Upper body keeps its artwork and moves only one pixel with weight transfer.
  for x in range(57):
   sway=round(math.sin(phase*math.tau-x*.13)*2*(57-x)/57)
   im.alpha_composite(cape.crop((x,0,x+1,96)),(x,bob+sway))
  im.alpha_composite(upper,(0,bob));atlas.alpha_composite(im,((i%8)*128,(i//8)*96));frames.append(im)
  if not armed:meta.append({'frame':i,'legs':points})
 name='armed' if armed else 'unarmed';atlas.save(OUT/(name+'.png'))
 contact=Image.new('RGBA',(128*8,96*2),(20,30,37,255));contact.alpha_composite(atlas);contact.save(OUT/'sources'/(name+'-contact.png'))
 frames=[f.resize((384,288),Image.Resampling.NEAREST) for f in frames]
 frames[0].save(OUT/'sources'/(name+'.gif'),save_all=True,append_images=frames[1:],duration=42,loop=0,disposal=2)
(OUT/'sources/poses.json').write_text(json.dumps(meta,indent=2)+'\n')
