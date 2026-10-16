extends "res://tools/prepare_hero_v005.gd"
const INPUT: String="res://art/concepts/hero-v011/sources/"
const OUTPUT: String="res://art/characters/hero-v011/"
func _initialize()->void:
 DirAccess.make_dir_recursive_absolute(OUTPUT)
 call_deferred("build")
func build()->void:
 for suffix:String in ["","-unarmed"]:
  var source:Array[Image]=cuts("motion"+suffix,16,4,4,INPUT)
  var factor:float=60.0/median_height(source.slice(8,16))
  var run:Array[Image]=[]
  var walk:Array[Image]=[]
  for i:int in range(16):
   var lift:int=[0,0,1,2,0,0,1,2][i%8] if i<8 else 0
   var tile:Image=native(source[i],factor,Vector2i(128,96),81,lift,torso_center(source[i]))
   if i<8:run.append(tile)
   else:walk.append(tile)
  pack(run,4,"gait-run"+suffix,OUTPUT)
  pack(walk,4,"gait-tired"+suffix,OUTPUT)
  var transition:Array[Image]=cuts("transition"+suffix,16,4,4,INPUT)
  var scale_factor:float=60.0/transition[0].get_height()
  var poses:Array[Image]=[]
  for i:int in range(16):poses.append(native(transition[i],scale_factor,Vector2i(128,96),81,0,torso_center(transition[i])))
  var idle:Image=Image.load_from_file("res://art/characters/hero-v011/idle"+suffix+".png").get_region(Rect2i(0,0,128,96))
  poses[0]=idle;poses[7]=idle
  poses[3]=run[0];poses[4]=run[0]
  # End the left pivot on the exact left-facing run contact used by the cycle.
  poses[15]=run[0].duplicate();poses[15].flip_x()
  pack(poses,4,"transition"+suffix,OUTPUT)
 var points:Dictionary={}
 for key:String in sockets:
  points[key]=[]
  for point:Vector2 in sockets[key]:points[key].append([point.x,point.y])
 var file:FileAccess=FileAccess.open(OUTPUT+"locomotion-sockets.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(points,"\t"));file.close()
 file=FileAccess.open(OUTPUT+"locomotion-metrics.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"native":metrics,"sources":source_metrics},"\t"));file.close()
 print("Hero v011 packing failures: ",failures)
 quit(1 if failures else 0)
func torso_center(tile:Image)->float:
 var xs:Array[int]=[]
 for y:int in range(int(tile.get_height()*0.35),int(tile.get_height()*0.53)):
  for x:int in range(tile.get_width()):
   var c:Color=tile.get_pixel(x,y)
   if c.a>0.8 and c.r>0.15 and c.g>c.r*0.72 and c.b>c.r*0.55:xs.append(x)
 if xs.is_empty():return face_center(tile)-9
 xs.sort();return xs[xs.size()/2]
