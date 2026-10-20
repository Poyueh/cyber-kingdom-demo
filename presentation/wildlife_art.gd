extends RefCounted
## Each silhouette is a native two-pixel grid, with its own measured stride.
const CAST: Array[WildlifeAppearance]=[
 null, preload("res://data/wildlife/hare.tres"), preload("res://data/wildlife/boar.tres"),
 preload("res://data/wildlife/fox.tres"), preload("res://data/wildlife/badger.tres"),
 preload("res://data/wildlife/goat.tres"), preload("res://data/wildlife/pheasant.tres"),
 preload("res://data/wildlife/tortoise.tres")]
const INK: String="abcde"

static func paint(canvas: Node2D, species: int, at: Vector2, direction: float, distance: float, moving: bool, tint: Color) -> void:
 var profile: WildlifeAppearance=CAST[species]
 var phase: float=distance/profile.stride*TAU
 canvas.draw_line(at+Vector2(-profile.shadow,1),at+Vector2(profile.shadow,1),Color(0.03,0.07,0.06,tint.a*0.32),2)
 var bounce: float=roundf(absf(sin(phase))*profile.bounce) if moving else 0.0
 canvas.draw_set_transform((at-Vector2(0,bounce)).round(),0,Vector2(direction,1))
 # Body, feet and tail freeze together when movement or simulation stops.
 for side: int in [-1,1]:
  for leg: int in range(profile.legs.size()):
   var cycle: float=phase+leg*PI+side
   var step: float=roundf(sin(cycle)*profile.step) if moving else 0.0
   var lift: float=roundf(maxf(0.0,cos(cycle))*profile.lift) if moving else 0.0
   var anchor: Vector2=profile.legs[leg]+Vector2(step,-lift)
   _box(canvas,Rect2(anchor,Vector2(4,-anchor.y-lift+bounce)),profile.colors[1 if side<0 else 2],tint)
   _box(canvas,Rect2(Vector2(anchor.x,-2-lift+bounce),Vector2(6,2)),profile.colors[0],tint)
 var sway: float=roundf(sin(phase)*profile.tail_sway) if moving else 0.0
 _pattern(canvas,profile.tail_rows,profile.tail_origin+Vector2(0,sway),profile.colors,tint)
 _pattern(canvas,profile.rows,profile.origin,profile.colors,tint)
 _details(canvas,profile.id,phase,moving,profile.colors,tint)
 canvas.draw_set_transform(Vector2.ZERO)

static func _details(canvas: Node2D, id: StringName, phase: float, moving: bool, ink: PackedColorArray, tint: Color) -> void:
 if id==&"hare":
  var ear: float=2.0 if moving and sin(phase)>0 else 0.0
  for x: float in [4.0,10.0]:
   _box(canvas,Rect2(x-ear,-36,4,14),ink[1],tint)
   _box(canvas,Rect2(x-ear,-34,2,10),ink[4],tint)
  _box(canvas,Rect2(-22,-14,6,6),ink[4],tint)
  _box(canvas,Rect2(12,-20,2,2),ink[0],tint)
 elif id==&"boar":
  _box(canvas,Rect2(10,-29,6,8),ink[1],tint)
  _box(canvas,Rect2(12,-27,2,4),ink[2],tint)
  _box(canvas,Rect2(15,-16,2,2),ink[0],tint)
  _box(canvas,Rect2(20,-10,2,6),ink[4],tint)
  _box(canvas,Rect2(-26,-17,4,2),ink[1],tint)
 elif id==&"goat":
  _box(canvas,Rect2(15,-28,2,2),ink[0],tint)
  _box(canvas,Rect2(14,-22,4,6),ink[3],tint)
 elif id==&"fox":
  _box(canvas,Rect2(16,-20,2,2),ink[0],tint)
 elif id==&"pheasant":
  _box(canvas,Rect2(10,-26,2,2),ink[0],tint)

static func _pattern(canvas: Node2D, rows: Array[String], origin: Vector2, ink: PackedColorArray, tint: Color) -> void:
 for y: int in range(rows.size()):
  for x: int in range(rows[y].length()):
   var color: int=INK.find(rows[y][x])
   if color>=0:_box(canvas,Rect2(origin+Vector2(x*2,y*2),Vector2(2,2)),ink[color],tint)

static func _box(canvas: Node2D, rect: Rect2, color: Color, tint: Color) -> void:
 canvas.draw_rect(rect,color*tint)
