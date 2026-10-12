extends SceneTree
var failures: int=0
var output: String="/tmp/cyber43-sky"
func _initialize() -> void:call_deferred("run")
func render_sky(size: Vector2i, night: bool, phase: float, halo: bool=true, disc: bool=true) -> Image:
 var viewport: SubViewport=SubViewport.new();viewport.size=size;viewport.world_2d=World2D.new();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var sky: Node2D=load("res://presentation/daylight_view.gd").new();sky.style=load("res://data/daylight_style.tres");viewport.add_child(sky)
 var texture: Image=Image.create(768,384,false,Image.FORMAT_RGBA8);texture.fill(Color(0.6,0.2,0.5))
 var clock: RefCounted=load("res://domain/campaign_clock.gd").new();clock.is_night=night
 clock.remaining=(clock.night_seconds if night else clock.day_seconds)*(1-phase)
 sky.present(clock,ImageTexture.create_from_image(texture),Rect2(Vector2.ZERO,Vector2(size)),false)
 if not halo:sky._material.set_shader_parameter("halo_strength",0.0)
 if not disc:sky._material.set_shader_parameter("sun_radius",0.0)
 await process_frame;await RenderingServer.frame_post_draw
 var result: Image=viewport.get_texture().get_image();viewport.queue_free();await process_frame
 return result
func delta(a: Color,b: Color) -> float:return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
func check(okay: bool,label: String) -> void:
 if not okay:failures+=1
 print("PASS: " if okay else "FAIL: ",label)
func run() -> void:
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--proof-prefix="):output=arg.trim_prefix("--proof-prefix=")
 for size: Vector2i in [Vector2i(960,300),Vector2i(960,700),Vector2i(1500,400)]:
  for night: bool in [false,true]:
   var baseline: Image=await render_sky(size,night,0.5,false,false)
   var disc: Image=await render_sky(size,night,0.5,false,true)
   var low: Vector2i=size;var high: Vector2i=Vector2i.ZERO;var count: int=0
   for y: int in range(size.y):
    for x: int in range(size.x):
     if delta(baseline.get_pixel(x,y),disc.get_pixel(x,y))>0.08:
      low=low.min(Vector2i(x,y));high=high.max(Vector2i(x,y));count+=1
   var extent: Vector2i=high-low+Vector2i.ONE
   check(count>20 and absi(extent.x-extent.y)<=2,"round softened disc %s night=%s extent=%s"%[size,night,extent])
   if size==Vector2i(960,300):
    var lit: Image=await render_sky(size,night,0.5)
    var halo_pixels: int=0
    for y: int in range(size.y):
     for x: int in range(size.x):
      if not Rect2i(low,extent).grow(3).has_point(Vector2i(x,y)) and delta(lit.get_pixel(x,y),disc.get_pixel(x,y))>0.003:halo_pixels+=1
    check(halo_pixels>100,"halo blends beyond disc night=%s pixels=%d"%[night,halo_pixels])
    lit.save_png(output+("-moon.png" if night else "-sun.png"))
 for night: bool in [false,true]:
  var before: Image=await render_sky(Vector2i(480,270),night,1.0)
  var after: Image=await render_sky(Vector2i(480,270),not night,0.0)
  var largest: float=0.0
  for y: int in range(270):
   for x: int in range(480):largest=maxf(largest,delta(before.get_pixel(x,y),after.get_pixel(x,y)))
  check(largest<=1.0/255.0,"continuous boundary from night=%s max channel delta=%f"%[night,largest])
 print("Native atmosphere failures: ",failures)
 quit(failures)
