extends RefCounted
## A compact plasma familiar on the same two-pixel grid as the world.
## The solid core never flickers: only peripheral energy slowly breathes.
const INK: Dictionary={"a":Color("102c48"),"b":Color("236b9b"),"c":Color("33bad5"),"d":Color("78eaf0"),"e":Color("ddffff"),"v":Color("6579c3")}
const HEAD: Array[String]=[
 ".....cccc.....","...ccddddcc...","..cdddeedddc..",".cddcaaaacddc.",
 ".cdbaaaaaabdc.",".cdaaaaaaaadc.","..cdaaaaaadc..","...ccddddcc..."]
const CORE: Array[String]=[
 "...bccddccb...","..bcddccddcb..",".bcddcaacddcb.",".bccddccddccb.",
 "..bcddeeddcb..","...bcddddcb...","....bcddcb....",".....bccb....."]

static func paint(canvas: Node2D, pose: Dictionary, celebrate: bool) -> void:
 canvas.draw_set_transform(pose.position.round())
 _body(canvas,pose.phase,pose.look,pose.lean,pose.direction,"celebrate" if celebrate else pose.state,1.0)
 canvas.draw_set_transform(Vector2.ZERO)

static func _body(canvas: Node2D, t: float, look: float, lean: float, direction: float, state: String, opacity: float) -> void:
 # Layered pixel corona, with no high-frequency noise or alpha holes in the body.
 for band: int in range(3):
  var glow: Color=INK.c;glow.a=opacity*(0.035+0.01*sin(t*1.8))/(band+1)
  var radius: float=28+band*2
  for row: int in range(-int(radius),int(radius),4):
   var half: float=roundf((20+band*3)*sqrt(maxf(0,1.0-pow(float(row)/radius,2)))/2)*2
   canvas.draw_rect(Rect2(-half,row,half*2,4),glow)
 for side: int in [-1,1]:
  for segment: int in range(6):
   var lag: float=roundf(sin(t*2.4-segment*0.5+side)*segment*0.6-lean*segment*0.45)*2
   var ink: Color=INK.c;ink.a=opacity*(0.72-segment*0.09)
   _pixel(canvas,Vector2(side*4+lag,12+segment*2),maxi(2,6-segment),ink)
 _pattern(canvas,CORE,Vector2(-14,-4),opacity)
 var head: Vector2=Vector2(roundf(look),roundf(sin(t*2.2)))*2
 _pattern(canvas,HEAD,Vector2(-14,-22)+head,opacity)
 var blink: bool=fposmod(t+0.8,4.7)>4.55
 for side: int in [-1,1]:
  var eye: Vector2=Vector2(side*4+roundf(look)*2,-12)+head
  _rect(canvas,Rect2(eye,Vector2(4,2 if blink else 4)),INK.e,opacity)
 # Orbiting capacitor segments replace the old gold crown.
 for i: int in range(4):
  var angle: float=PI+PI*i/3.0
  _pixel(canvas,Vector2(cos(angle)*13,-22+sin(angle)*5)+head,2,Color(0.4,0.77,1,opacity*0.85))
 _rect(canvas,Rect2(-2,0,4,8),INK.e,opacity)
 _rect(canvas,Rect2(-6,2,12,2),INK.d,opacity)
 # Tiny circuit paths make the plasma read as technology, not fabric.
 for side: int in [-1,1]:
  _rect(canvas,Rect2(side*8-1,0,2,6),INK.c,opacity)
  _pixel(canvas,Vector2(side*6,8),2,INK.e*Color(1,1,1,opacity))
 var beat: float=sin(t*3.0)
 var hand: Vector2=Vector2(18,4+roundf(beat)*2)
 var elbow: Vector2=Vector2(12,0)
 var facing: float=direction
 match state:
  "lead","return":hand=Vector2(22,-4+roundf(beat)*2)
  "greet","wait":facing=signf(look);elbow=Vector2(12,-6);hand=Vector2(18+roundf(beat)*2,-16)
  "point":hand=Vector2(22,2)
  "observe":hand=Vector2(12,8)
  "receive":hand=Vector2(20,0)
  "guard":elbow=Vector2(12,-8);hand=Vector2(16,-18)
  "celebrate":elbow=Vector2(12,-8);hand=Vector2(18,-20)
  "rest":hand=Vector2(14,10)
 if facing==0:facing=1
 _arm(canvas,Vector2(8*facing,-2),elbow*Vector2(facing,1),hand*Vector2(facing,1),opacity)
 _arm(canvas,Vector2(-8*facing,0),Vector2(-10*facing,4),Vector2(-14*facing,8+roundf(beat)*2),opacity)
 for i: int in range(3):
  var life: float=fposmod(t*0.35+i/3.0,1.0)
  var mote: Color=INK.d;mote.a=opacity*(1-life)*0.32
  _pixel(canvas,Vector2(-direction*(8+life*14),14+life*10),2,mote)

static func _pattern(canvas: Node2D, rows: Array[String], origin: Vector2, opacity: float) -> void:
 for y: int in range(rows.size()):
  for x: int in range(rows[y].length()):
   if INK.has(rows[y][x]):_rect(canvas,Rect2(origin+Vector2(x*2,y*2),Vector2(2,2)),INK[rows[y][x]],opacity)

static func _arm(canvas: Node2D, start: Vector2, elbow: Vector2, hand: Vector2, opacity: float) -> void:
 for pair: Array in [[start,elbow],[elbow,hand]]:
  var steps: int=maxi(1,int(pair[0].distance_to(pair[1])/2))
  for i: int in range(steps+1):_pixel(canvas,pair[0].lerp(pair[1],float(i)/steps),4,INK.c*Color(1,1,1,opacity))
 _pixel(canvas,hand,4,INK.e*Color(1,1,1,opacity))

static func _rect(canvas: Node2D, rect: Rect2, color: Color, opacity: float) -> void:
 color.a*=opacity;canvas.draw_rect(rect,color)

static func _pixel(canvas: Node2D, at: Vector2, width: int, color: Color) -> void:
 canvas.draw_rect(Rect2((at/2).round()*2-Vector2.ONE*floorf(width/2.0),Vector2.ONE*width),color)

static func projection(canvas: Node2D, at: Vector2, time: float, opacity: float) -> void:
 # Shrine has a local transform already; keep it rather than resetting the canvas.
 canvas.draw_set_transform(at)
 _body(canvas,time,1,0,1,"rest",opacity)
 canvas.draw_set_transform(Vector2.ZERO)
