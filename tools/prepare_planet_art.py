from PIL import Image
import numpy as np
from sprite_components import components
from pathlib import Path
r=Path(__file__).resolve().parents[1];src=r/'art/concepts/three-planets-v001/sources';out=r/'art/planets/v001';out.mkdir(parents=True,exist_ok=True)
def save_crop(im,box,name,width=None,height=None):
 p=im.crop(box);b=p.getbbox();p=p.crop(b)
 scale=min((width/p.width if width else 99),(height/p.height if height else 99));size=(max(1,round(p.width*scale)),max(1,round(p.height*scale)))
 p=p.resize(size,Image.Resampling.NEAREST)
 a=np.array(p);a[:,:,3]=np.where(a[:,:,3]>=150,255,0);p=Image.fromarray(a);p.save(out/(name+'.png'))
for n in ['desert-sky','frost-sky']:
 im=Image.open(src/(n+'.png')).convert('RGB');im.resize((640,320),Image.Resampling.NEAREST).save(out/(n+'.png'))
for n in ['sand-dragon','frost-dragon']:
 im=Image.open(src/(n+'.png')).convert('RGBA');a=np.array(im);a[:,:,3]=np.where(a[:,:,3]>=160,255,0);im=Image.fromarray(a)
 groups=components(np.array(im)[:,:,3]>0)[:4]
 groups.sort(key=lambda g:min(l for y,l,rr in g))
 frames=[]
 for group in groups:
  clean=np.zeros_like(np.array(im));original=np.array(im)
  for y,l,rr in group:clean[y,l:rr]=original[y,l:rr]
  frame=Image.fromarray(clean);frames.append(frame.crop(frame.getbbox()))
 boxes=[f.getbbox() for f in frames];factor=min(284/max(b[2]-b[0] for b in boxes),200/max(b[3]-b[1] for b in boxes))
 atlas=Image.new('RGBA',(320*4,224));
 for i,(f,b) in enumerate(zip(frames,boxes)):
  p=f.crop(b).resize((round((b[2]-b[0])*factor),round((b[3]-b[1])*factor)),Image.Resampling.NEAREST)
  atlas.alpha_composite(p,(i*320+(320-p.width)//2,220-p.height))
 atlas.save(out/(n+'.png'))
im=Image.open(src/'planet-props.png').convert('RGBA');w,h=im.size
# Generated atlas uses unequal columns: shipwreck/observatory have wider silhouettes.
for row,prefix in enumerate(['desert','frost']):
 for label,l,rr,mw,mh in [('tree',0,.225,150,240),('landmark',.228,.626,380,245),('ore',.632,.825,80,85),('shrub',.827,1,70,46)]:
  save_crop(im,(round(l*w),round(row*h/2),round(rr*w),round((row+1)*h/2)),prefix+'-'+label,mw,mh)
im=Image.open(src/'rocket.png').convert('RGBA');w,h=im.size
# All stages use the same downsampling scale and same ground baseline.
frames=[im.crop((round(i*w/3),0,round((i+1)*w/3),h)) for i in range(3)]
boxes=[f.getbbox() for f in frames];factor=180/max(b[3]-b[1] for b in boxes)
atlas=Image.new('RGBA',(180*3,188))
for i,(f,b) in enumerate(zip(frames,boxes)):
 p=f.crop(b).resize((round((b[2]-b[0])*factor),round((b[3]-b[1])*factor)),Image.Resampling.NEAREST);a=np.array(p);a[:,:,3]=np.where(a[:,:,3]>=150,255,0);p=Image.fromarray(a)
 atlas.alpha_composite(p,(i*180+(180-p.width)//2,184-p.height))
atlas.save(out/'rocket.png')
# Extract ground textures from the generated environment artwork, fixed native grid.
for name in ['desert','frost']:
 im=Image.open(src/(name+'-sky.png')).convert('RGB');w,h=im.size
 im.crop((round(w*.15),round(h*.90),round(w*.55),h)).resize((256,50),Image.Resampling.NEAREST).save(out/(name+'-ground.png'))
print('Processed',len(list(out.glob('*.png'))),'native pixel assets')
