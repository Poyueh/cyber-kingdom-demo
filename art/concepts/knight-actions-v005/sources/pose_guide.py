from PIL import Image,ImageDraw
im=Image.new('RGB',(1536,1152),'#25343d');d=ImageDraw.Draw(im)
k=[((16,65),(24,81),(-15,69),(-24,81)),((10,67),(14,81),(-15,64),(-18,75)),((0,68),(0,81),(9,61),(-5,68)),((-9,67),(-13,81),(15,59),(10,68)),((-15,65),(-24,75),(18,62),(24,75)),((-16,67),(-25,79),(17,65),(26,81))]
for i in range(12):
 ox=(i%4)*384;oy=(i//4)*384+25;s=3
 def pt(p):return (ox+p[0]*s,oy+p[1]*s)
 nk,nf,fk,ff=k[i%6]
 if i>=6:nk,nf,fk,ff=fk,ff,nk,nf
 hip=(65,55);shoulder=(73,34)
 d.line([pt((8,82)),pt((120,82))],fill='#52656b',width=2)
 d.polygon([pt((70,33)),pt((29,45)),pt((19,39)),pt((55,27))],fill='#a12b43')
 for knee,foot,color in [(fk,ff,'#586776'),(nk,nf,'#c8d5df')]:
  knee=(65+knee[0],knee[1]);foot=(65+foot[0],foot[1]);d.line([pt(hip),pt(knee),pt(foot)],fill=color,width=18);d.line([pt(foot),pt((foot[0]+7,foot[1]))],fill=color,width=15)
 d.line([pt(hip),pt(shoulder)],fill='#93aab5',width=29)
 d.line([pt(shoulder),pt((62,45)),pt((48,54))],fill='#98c6d5',width=13)
 d.line([pt((50,54)),pt((21,69))],fill='#53d8e5',width=9)
 d.line([pt((72,35)),pt((83,48)),pt((89-(i%6),43))],fill='#bacbd0',width=13)
 d.ellipse([pt((73,17)),pt((86,31))],fill='#becbd0');d.line([pt((81,24)),pt((87,24))],fill='#4befeb',width=9)
 d.text((ox+15,oy+290),str(i+1),fill='#d2dce1')
im.save('/tmp/knight-pose-guide.png')
