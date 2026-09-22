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
# Use the established silver idle armour for every locomotion leg, including idle.
armor=Image.open(ROOT/'art/characters/prosthetic-v001/knight-idle.png').convert('RGBA').crop((0,0,128,96)).resize((512,384),Image.Resampling.NEAREST)
def armor_part(points):
 mask=Image.new('L',armor.size);ImageDraw.Draw(mask).polygon([(x*4,y*4) for x,y in points],fill=255)
 piece=armor.copy();piece.putalpha(Image.fromarray(np.minimum(np.array(mask),np.array(armor.getchannel('A')))))
 return piece
thigh=armor_part([(69,56),(74,56),(76,62),(76,66),(70,66),(69,62)])
shin=armor_part([(70,65),(76,65),(76,70),(75,75),(70,75),(70,70)])
boot=armor_part([(70,74),(75,74),(77,76),(80,77),(80,79),(70,79)])
upper=part([(253,130),(274,135),(279,149),(263,167),(253,182),(236,176),(233,167),(242,143)])
fore=part([(236,169),(255,178),(244,200),(241,208),(226,212),(217,202),(220,188)])
# Render transformed original armor cutouts into one offline atlas. No runtime rig or nodes.
def place(im,p,a0,b0,a1,b1,dark=1,width=None):
 ax,ay=a0;bx,by=b0;cx,cy=[v*4 for v in a1];dx,dy=[v*4 for v in b1]
 vx,vy=bx-ax,by-ay;wx,wy=dx-cx,dy-cy
 den=vx*vx+vy*vy;u=(wx*vx+wy*vy)/den;v=(wy*vx-wx*vy)/den;det=u*u+v*v
 # Inverse affine: output coords -> original image coords.
 coeff=(u/det,v/det,ax-(u*cx+v*cy)/det,-v/det,u/det,ay-(-v*cx+u*cy)/det)
 if width is not None:
  # Stretch along the bone only: armour must not get wider as a leg extends.
  sl=math.hypot(vx,vy);tl=math.hypot(wx,wy)
  sx,sy=vx/sl,vy/sl;tx,ty=wx/tl,wy/tl
  aa=sx*tx*sl/tl+sy*ty/width;bb=sx*ty*sl/tl-sy*tx/width
  cc=sy*tx*sl/tl-sx*ty/width;dd=sy*ty*sl/tl+sx*tx/width
  coeff=(aa,bb,ax-aa*cx-bb*cy,cc,dd,ay-cc*cx-dd*cy)
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
  extension=(dist+.1)/(L1+L2);L1*=extension;L2*=extension
 along=(L1*L1-L2*L2+dist*dist)/(2*dist);h=math.sqrt(max(0,L1*L1-along*along));knee=(hip[0]+dx*along/dist+dy*h/dist,hip[1]+dy*along/dist-dx*h/dist)
 shade=1 if front else .65
 place(im,thigh,(72*4,57*4),(73*4,65*4),hip,knee,shade,width=1.15)
 place(im,shin,(73*4,66*4),(72.5*4,75*4),knee,foot,shade,width=1.15)
 # Heel follows the shin through the airborne recovery; sole remains flat on contact.
 lift=max(0,76-foot[1]);toe=(foot[0]+6,foot[1]+min(3,lift*.16))
 place(im,boot,(72.5*4,76*4),(79*4,77*4),foot,toe,shade)
 # Small shared joint hides seams where the plates rotate.
 d=ImageDraw.Draw(im);x,y=[round(v*4) for v in knee]
 d.ellipse((x-9,y-9,x+9,y+9),fill='#25323e' if front else '#192630');d.ellipse((x-5,y-5,x+5,y+5),fill='#94b3c1' if front else '#566d7b');d.point((x-2,y-3),fill='#e4f3f3')
def arm(im,shoulder,elbow,hand,front=True):
 place(im,upper,(263,142),(246,171),shoulder,elbow,1 if front else .65)
 place(im,fore,(246,178),(232,199),elbow,hand,1 if front else .65)
def stature(tile,anchor):
 # Keep the established combat sprite's roughly 56px stature, anchored at the soles.
 scale=.84;result=Image.new('RGBA',tile.size)
 small=tile.resize((round(tile.width*scale),round(tile.height*scale)),Image.Resampling.NEAREST)
 result.alpha_composite(small,(round(anchor[0]*(1-scale)),round(anchor[1]*(1-scale))))
 return result
for mode in ['run','sprint','walk','idle']:
 for armed in [False,True]:
  count=4 if mode=='idle' else 16
  columns=2 if mode=='idle' else 8
  frames=[];atlas=Image.new('RGBA',(256,192) if mode=='idle' else (1024,192))
  for i in range(count):
   t=i/count;im=Image.new('RGBA',(512,384))
   bob=.6*math.sin(t*math.tau*2)
   hip=(64,(47.0 if mode=='sprint' else 45.5)+bob);lean=2 if mode=='sprint' else 0
   keys=[(24,77),(8,77),(-10,77),(-24,76),(-24,70),(-12,66),(5,69),(21,75)]
   if mode=='sprint':keys=[(30,77),(10,77),(-14,77),(-30,75),(-27,67),(-13,63),(9,68),(27,74)]
   if mode=='walk':keys=[(10,77),(5,77),(0,77),(-6,77),(-10,77),(-6,75),(0,74),(7,75)];hip=(64,44+math.sin(t*math.tau*2)*.4)
   if mode=='idle':hip=(64,44.0+math.sin(t*math.tau)*.35)
   def foot(p):
    x,y=smooth(keys,p);return (64+x,y)
   # Cape gets a traveling wave, while its attachment stays fixed at the shoulder.
   cap=Image.new('RGBA',src.size)
   for x in range(60,324,4):
    wave=round(math.sin(t*math.tau-x*.025)*(324-x)/85)
    cap.alpha_composite(cape.crop((x,0,x+4,384)),(x,wave))
   body_hip=(274,198);body_top=(296,111)
   target_top=(61+lean,hip[1]-17.5)
   if mode=='idle':target_top=(61,hip[1]-17.5)
   place(im,cap,body_hip,body_top,hip,target_top)
   leg(im,(hip[0]-2,hip[1]),(57,77) if mode=='idle' else foot(t+.5),False)
   swing=0 if mode=='idle' else math.cos(t*math.tau)
   arm(im,(65+lean,hip[1]-14),(64+10*swing,hip[1]-4),(61+14*swing,hip[1]+2),False)
   place(im,body,body_hip,body_top,hip,target_top)
   leg(im,hip,(70,77) if mode=='idle' else foot(t),True)
   # Armed rear hand carries the blade; unarmed runner counter-swings both arms.
   shoulder=(63+lean,hip[1]-13)
   elbow=(56 if armed else 64-10*swing,hip[1]-4)
   hand=(51+2*math.sin(t*math.tau) if armed else 66-14*swing,hip[1]+3)
   if mode=='idle':elbow=(64,hip[1]-5);hand=(68,hip[1]+4)
   if armed:
    d=ImageDraw.Draw(im);x,y=[v*4 for v in hand]
    d.line((x,y,x-132,y+42),fill='#142733',width=15);d.line((x,y,x-126,y+38),fill='#b5ced1',width=8);d.line((x,y-3,x-125,y+35),fill='#e5f4eb',width=3);d.line((x-8,y-12,x+4,y+12),fill='#c49c48',width=6)
   arm(im,shoulder,elbow,hand)
   cell=stature(im.resize((128,96),Image.Resampling.NEAREST),(64,80))
   atlas.alpha_composite(cell,((i%columns)*128,(i//columns)*96));frames.append(cell)
  name=mode+('-armed' if armed else '-unarmed');atlas.save(OUT/(name+'.png'))
  if os.environ.get("ART_PREVIEWS")=="1":
   preview=Image.new('RGBA',atlas.size,'#17262c');preview.alpha_composite(atlas);preview.save(OUT/'sources'/(name+'-contact.png'))
   fs=[f.resize((384,288),Image.Resampling.NEAREST) for f in frames]
   fs[0].save(OUT/'sources'/(name+'.gif'),save_all=True,append_images=fs[1:],duration=32 if mode=='sprint' else 40 if mode=='run' else 70,loop=0,disposal=2)

def character_pose(hip,top,feet,hands,elbows,phase=0):
 """Ceremony and recovery use exactly the locomotion armour, head and scale."""
 im=Image.new('RGBA',(512,384))
 place(im,cape,(274,198),(296,111),hip,top)
 leg(im,(hip[0]-2,hip[1]),feet[0],False)
 arm(im,(top[0]+4,top[1]+5),elbows[0],hands[0],False)
 place(im,body,(274,198),(296,111),hip,top)
 leg(im,hip,feet[1],True)
 arm(im,(top[0]-2,top[1]+5),elbows[1],hands[1])
 tile=Image.new('RGBA',(160,128))
 tile.alpha_composite(im.resize((128,96),Image.Resampling.NEAREST),(16,16))
 return tile

def blade(tile,hand,tip):
 """One silver blade, anchored to the gauntlet; transparent margin allows the lift."""
 d=ImageDraw.Draw(tile);h=(hand[0]+16,hand[1]+16);p=(tip[0]+16,tip[1]+16)
 dx,dy=p[0]-h[0],p[1]-h[1];length=math.hypot(dx,dy)
 d.line([h,p],fill='#162936',width=4)
 d.line([h,p],fill='#b5ced1',width=2)
 d.line([(h[0]-1,h[1]),(p[0]-1,p[1])],fill='#e5f4eb',width=1)
 nx,ny=-dy/length*3,dx/length*3
 d.line([(h[0]+nx,h[1]+ny),(h[0]-nx,h[1]-ny)],fill='#c49c48',width=2)

# Eight existing ceremony timing slots: reach, brace, pull, rise, lift, hold, lower, settle.
poses=[
 ((64,44),(61,26.5),(77,50),(77,78)),
 ((64,49),(65,32),(78,53),(78,79)),
 ((64,48),(65,31),(77,49),(77,77)),
 ((64,44),(61,26.5),(74,40),(75,68)),
 ((64,44),(61,26.5),(71,17),(71,-14)),
 ((64,44),(61,26.5),(71,17),(71,-14)),
 ((64,44),(61,26.5),(72,38),(94,16)),
 ((64,44),(61,26.5),(68,48),(35,59)),
]
ceremony=Image.new('RGBA',(640,256))
for i,(hip,top,hand,tip) in enumerate(poses):
 offhand=(hand[0]-3,hand[1]+3) if i<4 else (70,48)
 elbows=((70,hip[1]-3),(70,30 if i in [4,5] else hip[1]-4))
 tile=character_pose(hip,top,[(57,77),(70,77)],[offhand,hand],elbows)
 blade(tile,hand,tip)
 ceremony.alpha_composite(stature(tile,(80,96)),((i%4)*160,(i//4)*128))
ceremony.save(ROOT/'art/characters/camp-ceremony-v001/draw_sword.png')

# Cavalry now reuses the mounted atlas directly at runtime; no second horse design.
rest_path=ROOT/'art/characters/exhaustion-v001/rest.png'
rest=Image.new('RGBA',(640,256))
for row in range(2):
 for i in range(4):
  breath=math.sin(i/6*math.tau)*.7
  hip=(64,45.5);top=(66+breath,29+breath)
  hand=(74,57) if row==0 else (76,45)
  tile=character_pose(hip,top,[(56,77),(72,77)],[(72,56),hand],[(73,46),(73,44)])
  if row==1:blade(tile,hand,(77,78))
  rest.paste(stature(tile,(80,96)),(i*160,row*128))
rest.save(rest_path)
