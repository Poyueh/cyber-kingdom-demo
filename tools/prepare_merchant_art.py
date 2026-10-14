"""Pack generated complete poses at one fixed scale; no pose invention or deformation."""
from pathlib import Path
import json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art/concepts/merchant-v001'
OUT=ROOT/'art/characters/merchant-v001'
def main():
 raw=Image.open(SOURCE/'merchant-source.png').convert('RGBA')
 atlas=Image.new('RGBA',(768,240))
 rows=[0,330,650,1024]
 frames=[]
 for row in range(3):
  for col in range(8):
   box=(col*192,rows[row],(col+1)*192,rows[row+1])
   tile=raw.crop(box)
   tile.putalpha(tile.getchannel('A').point(lambda a:255 if a>=145 else 0))
   bounds=tile.getbbox();assert bounds
   tile=tile.crop(bounds)
   native=tile.resize((round(tile.width*.21),round(tile.height*.21)),Image.Resampling.NEAREST)
   feet=native.crop((0,max(0,native.height-4),native.width,native.height)).getbbox()
   pivot=(feet[0]+feet[2])//2 if feet else native.width//2
   x=48-pivot;y=74-native.height
   assert x>=0 and y>=0 and x+native.width<=96
   atlas.alpha_composite(native,(col*96+x,row*80+y))
   frames.append({'tier':row+1,'frame':col,'source_cell':box,'crop':bounds,'position':[x,y],'size':native.size})
 OUT.mkdir(parents=True,exist_ok=True);atlas.save(OUT/'merchant.png')
 (SOURCE/'atlas.json').write_text(json.dumps({'generator':'built-in image_gen','native_scale':0.21,'cell':[96,80],'foot':[48,74],'frames':frames},indent=2)+'\n')
 print('Prepared 24 full-body merchant poses across three camp tiers.')
if __name__=='__main__':main()
