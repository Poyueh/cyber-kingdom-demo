extends RefCounted
## Small game uses full pixel silhouettes; legs, ears and bodies move together.
const HARE: Array[String]=[
 "...........bbbb.....","..........bcddcb....","..........bcdecba...","..bbbbb...bccdcb....",
 ".bccdddccccddccb....","bcddeedddddddcb.....","bcddddddddddcb......",".bccddddddccb.......","..bbbbbbbbbb........"]
const BOAR: Array[String]=[
 "......bbbbbbbbbb........","....bbccccdddddccbb.....","...bccccddddddddcccb....","..bccccddddddddddcccbb..",
 ".bccccddddddddddddccdcba","abccccddddddddddcccdccba",".bccccddddddddccccccbba.","..bccccddddccccccbbb....","...bbbbbbbbbbbbbb......"]
const HARE_INK: Dictionary={"a":Color("303a37"),"b":Color("635746"),"c":Color("a59570"),"d":Color("cab58a"),"e":Color("ece3bd")}
const BOAR_INK: Dictionary={"a":Color("34383b"),"b":Color("493d3c"),"c":Color("69504a"),"d":Color("96705a"),"e":Color("d6c6a0")}

static func paint(canvas: Node2D, species: int, at: Vector2, direction: float, phase: float, moving: bool, tint: Color) -> void:
 var rabbit: bool=species==1
 var ink: Dictionary=HARE_INK if rabbit else BOAR_INK
 var size: float=16.0 if rabbit else 23.0
 canvas.draw_line(at+Vector2(-size,1),at+Vector2(size,1),Color(0.03,0.07,0.06,tint.a*0.32),2)
 var bounce: float=roundf(absf(sin(phase))*(2 if rabbit else 1)) if moving else 0.0
 canvas.draw_set_transform((at-Vector2(0,bounce)).round(),0,Vector2(direction,1))
 # Alternating near/far feet follow distance travelled and freeze on pause.
 for side: int in [-1,1]:
  for leg: int in range(2):
   var step: float=roundf(sin(phase+leg*PI+side)*2) if moving else 0.0
   var foot: Vector2=Vector2((-9 if rabbit else -15)+leg*(18 if rabbit else 29)+step,-6)
   _box(canvas,Rect2(foot,Vector2(4,6)),ink.b if side<0 else ink.c,tint)
   _box(canvas,Rect2(foot+Vector2(0,4),Vector2(6,2)),ink.a,tint)
 _pattern(canvas,HARE if rabbit else BOAR,Vector2(-20 if rabbit else -24,-24),ink,tint)
 if rabbit:
  var ear: float=2.0 if moving and sin(phase)>0 else 0.0
  for x: float in [4.0,10.0]:
   _box(canvas,Rect2(x-ear,-36,4,14),ink.b,tint)
   _box(canvas,Rect2(x-ear,-34,2,10),ink.e,tint)
  _box(canvas,Rect2(-22,-14,6,6),ink.e,tint)
  _box(canvas,Rect2(12,-20,2,2),ink.a,tint)
 else:
  _box(canvas,Rect2(10,-29,6,8),ink.b,tint)
  _box(canvas,Rect2(12,-27,2,4),ink.c,tint)
  _box(canvas,Rect2(15,-16,2,2),ink.a,tint)
  _box(canvas,Rect2(20,-10,2,6),ink.e,tint)
  _box(canvas,Rect2(-26,-17,4,2),ink.b,tint)
 canvas.draw_set_transform(Vector2.ZERO)

static func _pattern(canvas: Node2D, rows: Array[String], origin: Vector2, ink: Dictionary, tint: Color) -> void:
 for y: int in range(rows.size()):
  for x: int in range(rows[y].length()):
   if ink.has(rows[y][x]):_box(canvas,Rect2(origin+Vector2(x*2,y*2),Vector2(2,2)),ink[rows[y][x]],tint)

static func _box(canvas: Node2D, rect: Rect2, color: Color, tint: Color) -> void:
 canvas.draw_rect(rect,color*tint)
