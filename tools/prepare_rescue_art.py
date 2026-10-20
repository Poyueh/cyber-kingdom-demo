from pathlib import Path
from PIL import Image
import numpy as np
root=Path(__file__).resolve().parent.parent
image=Image.open(root/'art/concepts/rescue-v001/source.png').convert('RGBA')
pixels=np.array(image)
pixels[:,:,3]=np.where(pixels[:,:,3]>=96,255,0)
image=Image.fromarray(pixels)
parts=[image.crop((0,0,image.width,440)),image.crop((0,440,image.width,image.height))]
boxes=[p.getbbox() for p in parts]
left=min(b[0] for b in boxes);right=max(b[2] for b in boxes)
scale=360/(right-left)
atlas=Image.new('RGBA',(384,224))
for index,(part,box) in enumerate(zip(parts,boxes)):
 frame=part.crop((left,box[1],right,box[3]))
 frame=frame.resize((360,round(frame.height*scale)),Image.Resampling.NEAREST)
 atlas.alpha_composite(frame,(12,index*112+106-frame.height))
atlas.save(root/'art/settlement/rescue-v001/rescue-ship.png')
