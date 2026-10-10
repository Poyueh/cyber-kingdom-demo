"""Reduce generated atlases once onto the shared native pixel grid, never at runtime."""
from pathlib import Path
from PIL import Image
import numpy as np
from sprite_components import components
ROOT=Path(__file__).resolve().parents[1]
SOURCES=ROOT/'art/concepts/seven-planets-v001/sources'
OUT=ROOT/'art/planets/v002'
OUT.mkdir(parents=True,exist_ok=True)
IDS=['swamp','volcanic','storm','void']
# Crop boundaries are measured on the saved production atlases, not assumed equal rows.
BANDS={'swamp':(260,300,646,647),'volcanic':(303,310,654,667),'storm':(290,300,685,705),'void':(290,300,645,648)}
PROP_X=[(0,407),(413,900),(901,1251),(1252,1536)]
def clean(image):
 a=np.array(image.convert('RGBA'));a[:,:,3]=np.where(a[:,:,3]>=155,255,0)
 return Image.fromarray(a)
def fit(image, w,h):
 image=image.crop(image.getbbox());scale=min(w/image.width,h/image.height)
 return image.resize((max(1,round(image.width*scale)),max(1,round(image.height*scale))),Image.Resampling.NEAREST)
for name in IDS:
 image=Image.open(SOURCES/(name+'.png')).convert('RGBA')
 sky_h,prop_top,prop_bottom,dragon_top=BANDS[name]
 # Preserve scenery proportions: wide panorama is cropped to a central 2:1 view.
 sky=image.crop((0,0,1536,sky_h)).convert('RGB')
 sky=sky.crop(((1536-sky_h*2)//2,0,(1536+sky_h*2)//2,sky_h)).resize((640,320),Image.Resampling.NEAREST)
 sky.save(OUT/(name+'-sky.png'))
 for (left,right),label,w,h in zip(PROP_X,['tree','landmark','ore','shrub'],[150,380,80,70],[240,245,85,46]):
  p=clean(image.crop((left,prop_top,right,prop_bottom)))
  fit(p,w,h).save(OUT/(name+'-'+label+'.png'))
 # Connected sprites can extend beyond nominal column borders (tails and wings).
 row=clean(image.crop((0,dragon_top,1536,1024)));pixels=np.array(row)
 groups=components(pixels[:,:,3]>0)
 major=groups[:4];major.sort(key=lambda g:min(l for y,l,r in g))
 centers=[sum((l+r)*(r-l)/2 for y,l,r in g)/sum(r-l for y,l,r in g) for g in major]
 sprites=[np.zeros_like(pixels) for _ in major]
 for g in groups:
  if sum(r-l for y,l,r in g)<5:continue
  cx=sum((l+r)*(r-l)/2 for y,l,r in g)/sum(r-l for y,l,r in g)
  index=major.index(g) if g in major else max([i for i,main in enumerate(major) if cx>=min(l for y,l,r in main)] or [0])
  for y,l,r in g:sprites[index][y,l:r]=pixels[y,l:r]
 frames=[Image.fromarray(a) for a in sprites]
 frames=[f.crop(f.getbbox()) for f in frames]
 scale=min(300/max(f.width for f in frames),207/max(f.height for f in frames))
 atlas=Image.new('RGBA',(1280,224))
 for i,f in enumerate(frames):
  f=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.NEAREST)
  atlas.alpha_composite(f,(320*i+(320-f.width)//2,220-f.height))
 atlas.save(OUT/(name+'-dragon.png'))
 # Ground strip from each atlas' low scenery, mirrored at both ends to tile cleanly.
 strip=image.crop((550,sky_h-21,742,sky_h-1)).convert('RGB').resize((128,50),Image.Resampling.NEAREST)
 tile=Image.new('RGB',(256,50));tile.paste(strip,(0,0));tile.paste(strip.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(128,0));tile.save(OUT/(name+'-ground.png'))
print('Built four scenery sets and four aligned dragon atlases on native pixel grid.')
