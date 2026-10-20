extends RefCounted
## Bounded presentation state follows actual displacement, including old saves.
const Finish = preload("res://data/scene_finish.tres")
const Art = preload("res://presentation/wildlife_art.gd")
const Ground = preload("res://presentation/grounded_art.gd")
var _source: RefCounted
var _positions: PackedFloat64Array=[]
var _directions: PackedFloat32Array=[]
var _distances: PackedFloat64Array=[]
var _moving: PackedByteArray=[]
var _time: float=-1.0

func present(sim: RefCounted) -> void:
 var animals: Array=sim.frontier.animals
 var now: float=sim.workforce.elapsed
 if not is_same(_source,sim) or _positions.size()!=animals.size() or now<_time:
  _source=sim
  _positions.resize(animals.size());_directions.resize(animals.size())
  _distances.resize(animals.size());_moving.resize(animals.size())
  for index: int in range(animals.size()):
   _positions[index]=animals[index].x;_directions[index]=1.0
   _distances[index]=0.0;_moving[index]=0
  _time=now
  return
 if now==_time:return
 for index: int in range(animals.size()):
  var travel: float=animals[index].x-_positions[index]
  _moving[index]=int(absf(travel)>0.005 and absf(travel)<8.0 and animals[index].alive)
  if _moving[index]:
   _directions[index]=signf(travel)
   _distances[index]+=absf(travel)
  _positions[index]=animals[index].x
 _time=now

func draw(canvas: Node2D, texture: Texture2D, index: int, at: Vector2, scale: float, tint: Color) -> void:
 # Stable slot identity expands visual species without adding prey or changing saves.
 if index%Art.CAST.size()!=0:
  Art.paint(canvas,index%Art.CAST.size(),at,_directions[index],_distances[index],_moving[index]!=0,tint)
  return
 var size: Vector2=texture.get_size()*scale
 var lift: float=roundf(absf(sin(_distances[index]/Finish.wildlife_stride*TAU))*Finish.wildlife_step_height) if _moving[index] else 0.0
 canvas.draw_line(at+Vector2(-11,1),at+Vector2(11,1),Color(0.03,0.07,0.06,tint.a*0.32),2)
 var origin: Vector2=Ground.anchor(texture,at,scale,false)-Vector2(size.x*0.5,size.y+lift)
 var rect: Rect2=Rect2(origin.round(),size)
 if _directions[index]<0:rect.size.x=-rect.size.x
 canvas.draw_texture_rect(texture,rect,false,tint)
