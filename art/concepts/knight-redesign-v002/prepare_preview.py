"""Pixel-size review only. These generated motion studies are not production clips."""
from pathlib import Path
from collections import deque
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'preview'
OUT.mkdir(exist_ok=True)

def clean(image):
    pixels = np.array(image.convert('RGBA'))
    pixels[:, :, 3] = np.where(pixels[:, :, 3] >= 180, 255, 0)
    return Image.fromarray(pixels)

def cut(sheet, index, columns, rows):
    w, h = sheet.size
    x, y = index % columns, index // columns
    return sheet.crop((round(x*w/columns), round(y*h/rows), round((x+1)*w/columns), round((y+1)*h/rows)))

def normalize(tile, scale):
    a = np.array(tile)
    yy, xx = np.indices(a.shape[:2])
    visor = (a[:,:,3]>0) & (a[:,:,1].astype(int)>a[:,:,0].astype(int)+45) & (a[:,:,2]>120)
    visor &= (xx>tile.width*.56) & (yy<tile.height*.46)
    xs = xx[visor]
    box = tile.getbbox()
    assert box and xs.size, 'Each study needs a visible visor and complete body.'
    face_x = float(np.median(xs))
    resized = tile.resize((round(tile.width*scale),round(tile.height*scale)),Image.Resampling.NEAREST)
    resized = resized.quantize(colors=32, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert('RGBA')
    cell = Image.new('RGBA',(128,96))
    cell.alpha_composite(resized,(round(73-face_x*scale),round(81-box[3]*scale)))
    # Strip tiny isolated fragments from blades spilling into neighbouring source cells.
    a=np.array(cell);seen=np.zeros(a.shape[:2],dtype=bool)
    for y,x in np.argwhere(a[:,:,3]>0):
        if seen[y,x]:continue
        queue=deque([(int(y),int(x))]);seen[y,x]=True;component=[]
        while queue:
            py,px=queue.popleft();component.append((py,px))
            for dy in [-1,0,1]:
                for dx in [-1,0,1]:
                    ny,nx=py+dy,px+dx
                    if 0<=ny<96 and 0<=nx<128 and not seen[ny,nx] and a[ny,nx,3]>0:
                        seen[ny,nx]=True;queue.append((ny,nx))
        if len(component)<12:
            for py,px in component:a[py,px]=0
    cell=Image.fromarray(a)
    return cell

for mode in ['run','slash']:
    sheet=clean(Image.open(ROOT/'sources'/f'{mode}.png'))
    first=cut(sheet,0,4,2)
    box=first.getbbox()
    scale=60/(box[3]-box[1])
    atlas=Image.new('RGBA',(512,192))
    for index in range(8):
        atlas.alpha_composite(normalize(cut(sheet,index,4,2),scale),((index%4)*128,(index//4)*96))
    atlas.save(OUT/f'{mode}.png')

design=clean(Image.open(ROOT/'sources/design.png'))
idle=cut(design,0,4,3)
box=idle.getbbox()
normalize(idle,60/(box[3]-box[1])).save(OUT/'idle.png')
design.resize((round(design.width/5),round(design.height/5)),Image.Resampling.NEAREST).save(OUT/'poses.png')
