from pathlib import Path
from PIL import Image
import numpy as np,shutil,json
dest=Path(__file__).resolve().parent.parent
src=dest/'sources/generated.png'
im=Image.open(src).convert('RGBA'); print(im.size,im.getextrema()[-1])
outputs=[Image.new('RGBA',(512,192)),Image.new('RGBA',(512,192))];info=[]
for row in range(4):
 for col in range(4):
  frame=im.crop((round(col*im.width/4),round(row*im.height/4),round((col+1)*im.width/4),round((row+1)*im.height/4)))
  a=np.array(frame);a[:,:,3]=np.where(a[:,:,3]>=150,255,0)
  mask=a[:,:,3]>0; ys,xs=np.where(mask);top=ys.min()
  helmet=mask & (np.indices(mask.shape)[0]<top+72) & (np.indices(mask.shape)[1]>frame.width*.5) & (a[:,:,1]>140) & (a[:,:,2]>145)
  hy,hx=np.where(helmet);assert len(hx)>20
  scale=.28;target=(round(frame.width*scale),round(frame.height*scale))
  small=Image.fromarray(a).resize(target,Image.Resampling.NEAREST)
  # Same visor/head anchor prevents lateral wobble. Preserve contact/flight differences in the feet.
  px=70-round(float(np.mean(hx))*scale);py=38-round(float(np.mean(hy))*scale)+[0,1,0,-1][col]
  cell=Image.new('RGBA',(128,96));cell.alpha_composite(small,(px,py))
  outputs[row//2].paste(cell,(col*128,(row%2)*96))
  info.append({'row':row,'column':col,'helmet_center':[float(np.mean(hx)),float(np.mean(hy))],'paste':[px,py]})
for n,im in zip(['armed.png','unarmed.png'],outputs):im.save(dest/n)
(dest/'sources/cutting.json').write_text(json.dumps(info,indent=2)+'\n')

