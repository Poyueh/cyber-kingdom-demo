"""Mechanical sprite production: alpha cutouts, fixed pixel scale and atlas packing.
Generated complete poses are preserved. No invented limbs or pose deformation.
"""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art/concepts/inhabitants-v001'
OUT=ROOT/'art/settlement/inhabitants-v001'
REVIEW=ROOT/'docs/reports/trail-inhabitants'
ROLES=['keeper','mechanic','seedkeeper','huntmaster','artificer','quartermaster']
BUILDINGS=['workshop','farm_tools','hunt_tools','armory','drill','outpost']

def cutout(im,box):
 tile=im.crop(box).convert('RGBA')
 tile.putalpha(tile.getchannel('A').point(lambda a:255 if a>=145 else 0))
 bounds=tile.getbbox()
 assert bounds is not None
 return tile.crop(bounds),bounds

def main():
 OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
 (REVIEW/'.gdignore').touch()
 raw=Image.open(SOURCE/'attendants.png')
 rows=[0,230,482,725,997,1251,1536]
 atlas=Image.new('RGBA',(384,480))
 meta={'tool':'built-in image_gen','staff_scale':0.21,'building_scale':0.3,'staff_cell':[96,80],'roles':ROLES,'frames':[]}
 for row,role in enumerate(ROLES):
  for col in range(4):
   tile,bounds=cutout(raw,(col*256,rows[row],(col+1)*256,rows[row+1]))
   native=tile.resize((round(tile.width*.21),round(tile.height*.21)),Image.Resampling.NEAREST)
   # Bottom silhouette anchors the feet, never a swinging tool or cape edge.
   feet=native.crop((0,max(0,native.height-4),native.width,native.height)).getbbox()
   pivot=(feet[0]+feet[2])//2 if feet else native.width//2
   x=48-pivot;y=74-native.height
   assert x>=0 and y>=0 and x+native.width<=96
   atlas.alpha_composite(native,(col*96+x,row*80+y))
   meta['frames'].append({'role':role,'frame':col,'source_bounds':bounds,'position':[x,y],'size':native.size})
 atlas.save(OUT/'attendants.png')
 contact=Image.new('RGBA',atlas.size,'#17222e');contact.alpha_composite(atlas)
 contact.resize((768,960),Image.Resampling.NEAREST).save(REVIEW/'attendants-contact.png')
 frames=[]
 for col in [0,1,2,3,2,1]:
  frame=Image.new('RGBA',(576,80),'#17222e')
  for row in range(6):frame.alpha_composite(atlas.crop((col*96,row*80,(col+1)*96,(row+1)*80)),(row*96,0))
  frames.append(frame.resize((1152,160),Image.Resampling.NEAREST).convert('RGB'))
 frames[0].save(REVIEW/'attendants-cycle.webp',save_all=True,append_images=frames[1:],duration=280,loop=0,lossless=True)
 raw=Image.open(SOURCE/'buildings.png');rows=[0,480,959,1536]
 contact=Image.new('RGBA',(512,600),'#17222e')
 for i,name in enumerate(BUILDINGS):
  row,col=divmod(i,2)
  tile,_=cutout(raw,(col*512,rows[row],(col+1)*512,rows[row+1]))
  native=tile.resize((round(tile.width*.3),round(tile.height*.3)),Image.Resampling.NEAREST)
  native.save(OUT/(name+'.png'))
  contact.alpha_composite(native,(col*256+128-native.width//2,row*200+182-native.height))
 contact.save(REVIEW/'buildings-contact.png')
 (OUT/'recipe.json').write_text(json.dumps(meta,indent=2)+'\n')
 print('Prepared 24 complete poses and 6 building silhouettes, fixed native scale.')
if __name__=='__main__':main()

# Optional third source sheet added in the same feature: fourteen grounded finds.
def prepare_trail_props():
 import numpy as np
 from sprite_components import components
 raw=np.array(Image.open(SOURCE/'trail-props.png').convert('RGBA'))
 def bounds(part):
  return min(l for _,l,_ in part),min(y for y,_,_ in part),max(r for _,_,r in part),max(y for y,_,_ in part)+1
 parts=sorted(components(raw[:,:,3]>=145),key=lambda p:sum(r-l for _,l,r in p),reverse=True)[:14]
 assert len(parts)==14
 parts.sort(key=lambda p:bounds(p)[3])
 ordered=[]
 for row in range(7):ordered.extend(sorted(parts[row*2:row*2+2],key=lambda p:bounds(p)[0]))
 atlas=Image.new('RGBA',(256,560))
 for index,part in enumerate(ordered):
  l,t,r,b=bounds(part)
  tile=np.zeros((b-t,r-l,4),dtype=np.uint8)
  for y,x,end in part:tile[y-t,x-l:end-l]=raw[y,x:end];tile[y-t,x-l:end-l,3]=255
  im=Image.fromarray(tile);im=im.resize((round(im.width*.18),round(im.height*.18)),Image.Resampling.NEAREST)
  assert im.width<=124 and im.height<=74
  atlas.alpha_composite(im,((index%2)*128+64-im.width//2,(index//2)*80+74-im.height))
 atlas.save(OUT/'trail-props.png')
 canvas=Image.new('RGBA',atlas.size,'#17222e');canvas.alpha_composite(atlas)
 canvas.resize((512,1120),Image.Resampling.NEAREST).save(REVIEW/'trail-props-contact.png')
 print('Prepared fourteen native roadside props.')
if __name__=='__main__':prepare_trail_props()
