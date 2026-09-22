from pathlib import Path
import math
import os
import numpy as np
from PIL import Image,ImageDraw,ImageEnhance
ROOT=Path(__file__).resolve().parents[4]
OUT=ROOT/'art/characters/grounded-run-v001';OUT.mkdir(exist_ok=True);(OUT/'sources').mkdir(exist_ok=True);(OUT/'sources/.gdignore').touch()
src=Image.open(ROOT/'art/characters/flight-run-v001/sources/generated.png').convert('RGBA').crop((0,0,512,384))
a=np.array(src);a[:,:,3]=np.where(a[:,:,3]>=150,255,0);src=Image.fromarray(a)
def part(poly):
 m=Image.new('L',src.size);ImageDraw.Draw(m).polygon(poly,fill=255)
 p=src.copy();p.putalpha(Image.fromarray(np.minimum(np.array(m),a[:,:,3])));return p
cape=part([(62,91),(162,88),(219,116),(282,75),(317,72),(319,115),(263,144),(179,190),(128,195),(78,164)])
body=part([(294,91),(322,52),(369,46),(389,75),(396,114),(365,137),(353,166),(325,186),(307,199),(275,215),(247,197),(257,172),(273,151),(278,128)])
thigh=part([(263,183),(285,185),(323,210),(347,227),(348,246),(329,252),(309,235),(269,216),(253,206)])
shin=part([(325,242),(348,240),(357,267),(382,307),(374,323),(360,319),(340,287),(321,264)])
boot=part([(361,310),(377,304),(386,308),(414,310),(427,309),(426,321),(402,332),(373,339),(357,329)])
upper=part([(253,130),(274,135),(279,149),(263,167),(253,182),(236,176),(233,167),(242,143)])
fore=part([(236,169),(255,178),(244,200),(241,208),(226,212),(217,202),(220,188)])
# Render transformed original armor cutouts into one offline atlas. No runtime rig or nodes.
def place(im,p,a0,b0,a1,b1,dark=1):
 ax,ay=a0;bx,by=b0;cx,cy=[v*4 for v in a1];dx,dy=[v*4 for v in b1]
 vx,vy=bx-ax,by-ay;wx,wy=dx-cx,dy-cy
 den=vx*vx+vy*vy;u=(wx*vx+wy*vy)/den;v=(wy*vx-wx*vy)/den;det=u*u+v*v
 # Inverse affine: output coords -> original image coords.
 coeff=(u/det,v/det,ax-(u*cx+v*cy)/det,-v/det,u/det,ay-(-v*cx+u*cy)/det)
 pp=p.transform((512,384),Image.Transform.AFFINE,coeff,Image.Resampling.NEAREST)
 if dark!=1:
  aa=pp.getchannel('A');pp=ImageEnhance.Brightness(pp).enhance(dark);pp.putalpha(aa)
 im.alpha_composite(pp)
def smooth(keys,t):
 t=t%1;n=len(keys);q=t*n;i=int(q);f=q-i
 p0=keys[(i-1)%n];p1=keys[i];p2=keys[(i+1)%n];p3=keys[(i+2)%n]
 return tuple(.5*((2*p1[k])+(-p0[k]+p2[k])*f+(2*p0[k]-5*p1[k]+4*p2[k]-p3[k])*f*f+(-p0[k]+3*p1[k]-3*p2[k]+p3[k])*f**3) for k in range(2))
def leg(im,hip,foot,front):
 dx,dy=foot[0]-hip[0],foot[1]-hip[1];dist=math.hypot(dx,dy);L1,L2=17,18
 if dist>L1+L2-.1:
  k=(L1+L2-.1)/dist;foot=(hip[0]+dx*k,hip[1]+dy*k);dx*=k;dy*=k;dist*=k
 along=(L1*L1-L2*L2+dist*dist)/(2*dist);h=math.sqrt(max(0,L1*L1-along*along));knee=(hip[0]+dx*along/dist+dy*h/dist,hip[1]+dy*along/dist-dx*h/dist)
 shade=1 if front else .65
 place(im,thigh,(274,198),(337,238),hip,knee,shade)
 place(im,shin,(337,250),(371,314),knee,foot,shade)
 # Heel follows the shin through the airborne recovery; sole remains flat on contact.
 lift=max(0,76-foot[1]);toe=(foot[0]+6,foot[1]+min(3,lift*.16))
 place(im,boot,(372,320),(407,319),foot,toe,shade)
 # Small shared joint hides seams where the plates rotate.
 d=ImageDraw.Draw(im);x,y=[round(v*4) for v in knee]
 d.ellipse((x-9,y-9,x+9,y+9),fill='#50370f' if front else '#342c1b');d.ellipse((x-5,y-5,x+5,y+5),fill='#d99b25' if front else '#846223');d.point((x-2,y-3),fill='#fff3ab')
def arm(im,shoulder,elbow,hand,front=True):
 place(im,upper,(263,142),(246,171),shoulder,elbow,1 if front else .65)
 place(im,fore,(246,178),(232,199),elbow,hand,1 if front else .65)
for mode in ['run','sprint','walk']:
 for armed in [False,True]:
  frames=[];atlas=Image.new('RGBA',(1024,192))
  for i in range(16):
   t=i/16;im=Image.new('RGBA',(512,384))
   bob=1.0*math.sin(t*math.tau*2)
   hip=(64,(48.5 if mode=='sprint' else 46.5)+bob);lean=3 if mode=='sprint' else 0
   keys=[(16,77),(3,77),(-15,77),(-20,72),(-16,64),(0,66),(13,69),(19,74)]
   if mode=='sprint':keys=[(21,76),(4,77),(-19,77),(-25,67),(-16,51),(0,54),(16,61),(24,69)]
   if mode=='walk':keys=[(10,77),(5,77),(0,77),(-6,77),(-10,77),(-6,75),(0,74),(7,75)];hip=(64,44+math.sin(t*math.tau*2)*.4)
   def foot(p):
    x,y=smooth(keys,p);return (64+x,y)
   # Cape gets a traveling wave, while its attachment stays fixed at the shoulder.
   cap=Image.new('RGBA',src.size)
   for x in range(60,324,4):
    wave=round(math.sin(t*math.tau-x*.025)*(324-x)/85)
    cap.alpha_composite(cape.crop((x,0,x+4,384)),(x,wave))
   body_hip=(274,198);body_top=(296,111)
   target_top=(68+lean,hip[1]-16.5)
   place(im,cap,body_hip,body_top,hip,target_top)
   leg(im,(hip[0]-2,hip[1]),foot(t+.5),False)
   swing=math.cos(t*math.tau)
   arm(im,(70+lean,hip[1]-11),(71+lean+8*swing,hip[1]-2),(77+lean+7*swing,hip[1]-9),False)
   place(im,body,body_hip,body_top,hip,target_top)
   leg(im,hip,foot(t),True)
   # Armed rear hand carries the blade; unarmed runner counter-swings both arms.
   shoulder=(63+lean,hip[1]-13)
   elbow=(59+(2 if armed else -7*swing),hip[1]-5)
   hand=(55+(2*math.sin(t*math.tau) if armed else -9*swing),hip[1]+3 if armed else hip[1]-2)
   if armed:
    d=ImageDraw.Draw(im);x,y=[v*4 for v in hand]
    d.line((x,y,x-132,y+42),fill='#142733',width=15);d.line((x,y,x-126,y+38),fill='#b5ced1',width=8);d.line((x,y-3,x-125,y+35),fill='#e5f4eb',width=3);d.line((x-8,y-12,x+4,y+12),fill='#c49c48',width=6)
   arm(im,shoulder,elbow,hand)
   cell=im.resize((128,96),Image.Resampling.NEAREST)
   atlas.alpha_composite(cell,((i%8)*128,(i//8)*96));frames.append(cell)
  name=mode+('-armed' if armed else '-unarmed');atlas.save(OUT/(name+'.png'))
  if os.environ.get("ART_PREVIEWS")=="1":
   preview=Image.new('RGBA',atlas.size,'#17262c');preview.alpha_composite(atlas);preview.save(OUT/'sources'/(name+'-contact.png'))
   fs=[f.resize((384,288),Image.Resampling.NEAREST) for f in frames]
   fs[0].save(OUT/'sources'/(name+'.gif'),save_all=True,append_images=fs[1:],duration=32 if mode=='sprint' else 40 if mode=='run' else 70,loop=0,disposal=2)
