extends RefCounted
## Native two-pixel artwork: articulated hood, eyes, sleeves, crystal heart and wisps.
const INK: Dictionary={"a":Color("234551"),"b":Color("367b87"),"c":Color("67bcb9"),"d":Color("a7e2d1"),"e":Color("e2fff1"),"g":Color("d9bd83")}
const HOOD: Array[String]=[
 "........bbb.........", "......bbcccbb.......", ".....bcdddcccb......",
 "....bcdeeedcccb.....", "...bcddcccccccb.....", "...bcdbaaaaabcb.....",
 "..bcdbbaaaaabbcb....", "..bcdbaaaaaaabcb....", "...bcbaaaaaaabcb....",
 "...bcddbaaaabdcb....", "....bcddbbbddcb.....", ".....bccdddccb......"]
const CLOAK: Array[String]=[
 ".......gggg.........", "....bbbcddcbbb......", "...bcddcddcddcb.....",
 "..bcddccddccddcb....", "...bccdcddcdccb.....", "....bccddddccb......",
 ".....bcddddcb.......", ".....bcddddcb.......", "....bccddddccb......",
 "....bcddddddcb......", "...bcddccccddcb.....", "...bcccb..bccccb....",
 "....bcb....bccb.....", "....bb......bb......"]

static func paint(canvas: Node2D, pose: Dictionary, celebrate: bool) -> void:
 var at: Vector2=pose.position
 var t: float=pose.phase
 var look: float=pose.look
 var state: String="celebrate" if celebrate else pose.state
 var lean: float=roundf(pose.lean)
 var beat: float=sin(t*3.6)
 # A few fading motes, never a screen-wide trail or collision surface.
 for i: int in range(4):
  var life: float=fposmod(t*0.55+i*0.25,1.0)
  var tail: Vector2=Vector2(-pose.direction*(12+life*24)-lean,18+life*21)
  _pixel(canvas,at+tail,2,Color(0.46,0.84,0.80,(1-life)*0.38))
 canvas.draw_set_transform(at.round())
 # Two separate cloth tails lag behind forward motion.
 for side: int in [-1,1]:
  for i: int in range(7):
   var sway: float=roundf(sin(t*3.2-i*0.42+side)*i*0.65-lean*i*0.7)
   _pixel(canvas,Vector2(side*7+sway,13+i*3),maxi(2,7-i),Color(0.35,0.73,0.73,0.72-i*0.07))
 _pattern(canvas,CLOAK,Vector2(-20,-7),t,lean,true)
 # Head tracks the knight independently; the whole body never snaps to its mirror.
 var head: Vector2=Vector2(roundf(look*2+lean*0.5),roundf(sin(t*2.6)*1.2))
 _pattern(canvas,HOOD,Vector2(-20,-29)+head,t,0,false)
 var blink: bool=fposmod(t+0.8,4.7)>4.53
 var eye_y: float=-15+head.y
 for side: int in [-1,1]:
  var eye: Vector2=Vector2(side*5+roundf(look*1.5)+head.x,eye_y)
  if state=="celebrate":
   _pixel(canvas,eye+Vector2(-2,0),2,INK.e);_pixel(canvas,eye+Vector2(0,-2),2,INK.e);_pixel(canvas,eye+Vector2(2,0),2,INK.e)
  else:canvas.draw_rect(Rect2(eye.round(),Vector2(4,2 if blink else 4)),INK.e)
 _pixel(canvas,Vector2(roundf(look)+head.x,-7+head.y),2,INK.c)
 # Small warm broken crown, with staggered highlights instead of a large UI halo.
 for i: int in range(5):
  var angle: float=PI+float(i)*PI/4+sin(t*1.4)*0.12
  var crown: Vector2=Vector2(cos(angle)*18,-29+sin(angle)*7)+head
  _pixel(canvas,crown,3,Color(0.85,0.74,0.52,0.60+0.18*sin(t*2+i)))
 # Breathing crystal set into the clasp.
 var heart: Vector2=Vector2(lean*0.4,1)
 _diamond(canvas,heart,5,INK.b);_diamond(canvas,heart,3,Color(0.80,1,0.91,0.8+0.2*sin(t*3)))
 var facing: float=pose.direction
 var elbow: Vector2=Vector2(17,3)
 var hand: Vector2=Vector2(20,9+beat*2)
 match state:
  "lead","return":elbow=Vector2(17,1-absf(beat)*2);hand=Vector2(25,-2-beat*3)
  "greet","wait":
   facing=signf(look);elbow=Vector2(17,-7);hand=Vector2(22+beat*4,-19-absf(beat)*3)
  "point":elbow=Vector2(20,-1);hand=Vector2(29,7+sin(t*2)*2)
  "observe":elbow=Vector2(15,5);hand=Vector2(11,9+sin(t*1.8)*2)
  "receive":elbow=Vector2(18,2);hand=Vector2(27,1-absf(beat)*3)
  "guard":elbow=Vector2(18,-7);hand=Vector2(20,-21+sin(t*2)*1.5)
  "celebrate":elbow=Vector2(17,-12);hand=Vector2(21,-28)
  "rest":elbow=Vector2(13,6);hand=Vector2(18,12)
 if facing==0:facing=1
 _arm(canvas,Vector2(11*facing,-1),elbow*Vector2(facing,1),hand*Vector2(facing,1))
 var back: Vector2=Vector2(-17*facing,6+sin(t*2.4+1)*3)
 if state=="receive":back=Vector2(-23*facing,2)
 if state=="celebrate":back=Vector2(-19*facing,-21)
 _arm(canvas,Vector2(-10*facing,0),Vector2(-14*facing,3),back)
 if celebrate:
  for i: int in range(5):
   var angle: float=TAU*i/5+t
   _pixel(canvas,Vector2(cos(angle),sin(angle))*34,2,INK.g)
 canvas.draw_set_transform(Vector2.ZERO)

static func _pattern(canvas: Node2D, rows: Array[String], origin: Vector2, t: float, lean: float, cloth: bool, opacity: float=1.0) -> void:
 for y: int in range(rows.size()):
  var sway: float=roundf(sin(t*2.8-y*0.23)*maxf(0,y-5)*0.15-lean*maxf(0,y-3)*0.12) if cloth else 0.0
  for x: int in range(rows[y].length()):
   var ink: String=rows[y][x]
   if INK.has(ink):
    var color: Color=INK[ink];color.a=(0.91 if not cloth else 0.9-y*0.014)*opacity
    canvas.draw_rect(Rect2((origin+Vector2(x*2+sway,y*2)).round(),Vector2(2,2)),color)

static func _arm(canvas: Node2D, shoulder: Vector2, elbow: Vector2, hand: Vector2) -> void:
 _stroke(canvas,shoulder,elbow,6,INK.b)
 _stroke(canvas,elbow,hand,4,INK.d)
 _pixel(canvas,hand,5,INK.e)

static func _stroke(canvas: Node2D, start: Vector2, end: Vector2, width: int, color: Color) -> void:
 var steps: int=maxi(1,int(start.distance_to(end)/2))
 for i: int in range(steps+1):_pixel(canvas,start.lerp(end,float(i)/steps),width,color)

static func _pixel(canvas: Node2D, point: Vector2, width: int, color: Color) -> void:
 canvas.draw_rect(Rect2((point/2).round()*2-Vector2.ONE*floorf(width/2.0),Vector2.ONE*width),color)

static func _diamond(canvas: Node2D, at: Vector2, radius: int, color: Color) -> void:
 for y: int in range(-radius,radius+1,2):
  var half: int=radius-absi(y)
  canvas.draw_rect(Rect2((at+Vector2(-half,y)).round(),Vector2(maxi(2,half*2),2)),color)

static func projection(canvas: Node2D, at: Vector2, time: float, opacity: float) -> void:
 _pattern(canvas,CLOAK,at+Vector2(-20,-7),time,0,true,opacity)
 _pattern(canvas,HOOD,at+Vector2(-20,-29),time,0,false,opacity)
 for side: int in [-1,1]:
  var eye: Color=INK.e;eye.a=opacity
  _pixel(canvas,at+Vector2(side*5,-14),3,eye)
