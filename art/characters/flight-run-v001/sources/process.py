from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
DEST=Path(__file__).resolve().parent.parent
source=Image.open(DEST/'sources/generated.png').convert('RGBA')
# Fixed scale preserves proportions; align hips horizontally and ground contacts vertically.
SCALE=.19
hands=[(235,200),(239,196),(234,207),(244,179),(240,209),(244,210),(241,230),(255,222)]
outputs={key:Image.new('RGBA',(512,192)) for key in ['run-unarmed','run-armed','sprint-unarmed','sprint-armed']}
for i in range(8):
 frame=source.crop(((i%4)*512,(i//4)*384,(i%4+1)*512,(i//4+1)*384))
 a=np.array(frame);a[:,:,3]=np.where(a[:,:,3]>=150,255,0)
 small=Image.fromarray(a).resize((97,73),Image.Resampling.NEAREST)
 a=np.array(small);ys,xs=np.where(a[:,:,3]>0)
 # Preserve an actual two-foot flight between contacts.
 floor=[80,80,76,73,80,80,76,73][i]
 px=64-round(hands[i][0]*SCALE);py=floor-int(ys.max())
 for mode in ['run','sprint']:
  for armed in [False,True]:
   cell=Image.new('RGBA',(128,96))
   cell.alpha_composite(small,(px,py))
   if armed:
    x=px+round(hands[i][0]*SCALE);y=py+round(hands[i][1]*SCALE)
    d=ImageDraw.Draw(cell)
    # Trail the sword behind the same moving fist. Only the blade is added.
    d.line((x,y,x-34,y+13),fill='#152b33',width=4)
    d.line((x,y,x-33,y+12),fill='#bddcdb',width=2)
    d.line((x,y-1,x-30,y+10),fill='#effaf0',width=1)
    d.line((x-3,y-4,x+1,y+4),fill='#a98b3a',width=2)
   if mode=='sprint':
    # Forward shear around the planted baseline increases the sprint lean.
    cell=cell.transform((128,96),Image.Transform.AFFINE,(1,.12,-9.6,0,1,0),resample=Image.Resampling.NEAREST)
   outputs[mode+('-armed' if armed else '-unarmed')].alpha_composite(cell,((i%4)*128,(i//4)*96))
for name,atlas in outputs.items():
 atlas.save(DEST/(name+'.png'))
 preview=Image.new('RGBA',atlas.size,'#17262c');preview.alpha_composite(atlas);preview.save(DEST/'sources'/(name+'-contact.png'))
 frames=[]
 for i in range(8):
  f=atlas.crop(((i%4)*128,(i//4)*96,(i%4+1)*128,(i//4+1)*96)).resize((384,288),Image.Resampling.NEAREST)
  frames.append(f)
 frames[0].save(DEST/'sources'/(name+'.gif'),save_all=True,append_images=frames[1:],duration=50 if name.startswith('run') else 36,loop=0,disposal=2)
