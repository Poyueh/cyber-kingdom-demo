from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
im=Image.open(root/'art/concepts/mount-expedition-v001/source.png').convert('RGBA')
out=root/'art/structures/mount-v001';out.mkdir(parents=True,exist_ok=True)
for i,name in enumerate(['cradle','stable']):
    crop=im.crop((i*im.width//2,0,(i+1)*im.width//2,im.height))
    crop=crop.crop(crop.getbbox())
    # One native image pixel per world pixel, matching the 60px rider.
    width=196
    crop=crop.resize((width,round(crop.height*width/crop.width)),Image.Resampling.NEAREST)
    crop.putalpha(crop.getchannel('A').point(lambda x:255 if x>=150 else 0))
    crop.save(out/(name+'.png'))

crop=im.crop((round(im.width*.035),round(im.height*.67),round(im.width*.145),round(im.height*.925)))
crop=crop.crop(crop.getbbox())
crop=crop.resize((70,round(crop.height*70/crop.width)),Image.Resampling.NEAREST)
crop.putalpha(crop.getchannel('A').point(lambda x:255 if x>=150 else 0))
crop.save(out/'junction.png')
