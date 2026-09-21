from pathlib import Path
from PIL import Image,ImageDraw,ImageEnhance
import math
import os
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'art/characters/raider-motion-v001';OUT.mkdir(exist_ok=True);(OUT/'sources').mkdir(exist_ok=True);(OUT/'sources/.gdignore').touch()
src=Image.open(ROOT/'art/characters/sentinel/processed/sentinel-v001.png').convert('RGBA').crop((0,0,128,96))
def part(poly):
 p=src.copy();mask=Image.new('L',src.size);ImageDraw.Draw(mask).polygon(poly,fill=255)
 from PIL import ImageChops
 p.putalpha(ImageChops.darker(mask,src.getchannel('A')));return p
body=part([(0,0),(128,0),(128,96),(77,96),(75,62),(69,62),(61,63),(58,57),(0,57)])
thigh=part([(60,56),(67,60),(63,66),(60,71),(54,72),(52,69),(56,63)])
shin=part([(54,68),(61,70),(56,74),(55,78),(51,80),(48,77),(51,71)])
boot=part([(49,75),(55,76),(58,78),(58,81),(49,81),(48,78)])
def place(im,p,a,b,c,d,shade=1):
 vx,vy=b[0]-a[0],b[1]-a[1];wx,wy=d[0]-c[0],d[1]-c[1];den=vx*vx+vy*vy;u=(wx*vx+wy*vy)/den;v=(wy*vx-wx*vy)/den;det=u*u+v*v
 q=p.transform((128,96),Image.Transform.AFFINE,(u/det,v/det,a[0]-(u*c[0]+v*c[1])/det,-v/det,u/det,a[1]-(-v*c[0]+u*c[1])/det),Image.Resampling.NEAREST)
 if shade!=1:
  alpha=q.getchannel('A');q=ImageEnhance.Brightness(q).enhance(shade);q.putalpha(alpha)
 im.alpha_composite(q)
def leg(im,hip,foot,near):
 dx,dy=foot[0]-hip[0],foot[1]-hip[1];dist=math.hypot(dx,dy);length=10
 if dist>19.9:
  ratio=19.9/dist;dx*=ratio;dy*=ratio;dist*=ratio;foot=(hip[0]+dx,hip[1]+dy)
 bend=math.sqrt(max(0,length*length-dist*dist/4));knee=((hip[0]+foot[0])/2+dy/dist*bend,(hip[1]+foot[1])/2-dx/dist*bend)
 shade=1 if near else .72
 place(im,thigh,(62,60),(57,69),hip,knee,shade);place(im,shin,(56,69),(52,77),knee,foot,shade);place(im,boot,(52,78),(56,79),foot,(foot[0]+4,foot[1]+1),shade)
atlas=Image.new('RGBA',(1024,192));frames=[]
for i in range(16):
 p=i/16;im=Image.new('RGBA',(128,96));bob=math.sin(p*math.tau*2)*.8;hip=(64,61+bob)
 def foot(phase):
  t=phase%1
  return (73-34*t,78) if t<.55 else (54.3+(t-.55)/.45*18.7,78-8*math.sin((t-.55)/.45*math.pi))
 leg(im,hip,foot(p+.5),False)
 place(im,body,(64,60),(64,35),hip,(65+math.sin(p*math.tau)*.7,36+bob))
 leg(im,hip,foot(p),True)
 atlas.alpha_composite(im,((i%8)*128,(i//8)*96));frames.append(im)
atlas.save(OUT/'run.png')
if os.environ.get('ART_PREVIEWS')=='1':
 preview=Image.new('RGBA',atlas.size,'#17262c');preview.alpha_composite(atlas);preview.save(OUT/'sources/contact.png')
 frames=[im.resize((384,288),Image.Resampling.NEAREST) for im in frames]
 frames[0].save(OUT/'sources/run.gif',save_all=True,append_images=frames[1:],duration=45,loop=0,disposal=2)
