"""Mechanical fixed-scale atlas packing only. Artwork is authored by image_gen.
Threshold alpha onto the native pixel grid, crop equal source cells and register
contact soles/hooves. A single scale applies to each entire character cycle.
"""
from pathlib import Path
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parent.parent
SOURCE=ROOT/'art/concepts/defense-mount-v001'
for name,scale,size,baseline,dest in [('guard',.185,(64,64),62,'sword-guard-v001/guard'),('mounted',.36,(160,128),96,'mounted-v002/mounted'),('mounted-unarmed',.36,(160,128),96,'mounted-v002/mounted-unarmed')]:
 path=SOURCE/(name+'.png')
 if not path.exists():continue
 image=Image.open(path).convert('RGBA');pixels=np.array(image);pixels[:,:,3]=np.where(pixels[:,:,3]>=96,255,0);image=Image.fromarray(pixels)
 atlas=Image.new('RGBA',(size[0]*8,size[1]*2))
 for index in range(16):
  col,row=index%4,index//4
  cell=image.crop((round(col*image.width/4),round(row*image.height/4),round((col+1)*image.width/4),round((row+1)*image.height/4)))
  box=cell.getbbox()
  if box is None:raise ValueError((name,index))
  frame=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST)
  feet=round(box[3]*scale)
  lift=3 if name.startswith('mounted') and index in [3,7] else 0
  x=index%8*size[0]+round((size[0]-frame.width)/2)
  y=index//8*size[1]+baseline-feet-lift
  atlas.alpha_composite(frame,(x,y))
 target=ROOT/'art/characters'/Path(dest+'.png');target.parent.mkdir(parents=True,exist_ok=True);atlas.save(target)
 print(target.relative_to(ROOT),atlas.size)
