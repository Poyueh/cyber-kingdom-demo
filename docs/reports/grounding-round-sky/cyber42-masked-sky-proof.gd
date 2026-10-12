extends SceneTree
var failures: int=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var output: String="/tmp/cyber42-sky-before"
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--proof-prefix="):output=arg.trim_prefix("--proof-prefix=")
 for size: Vector2i in [Vector2i(960,300),Vector2i(960,700),Vector2i(1500,400)]:
  for night: bool in [false,true]:
   var viewport: SubViewport=SubViewport.new();viewport.size=size;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.world_2d=World2D.new()
   root.add_child(viewport)
   var sky: Node2D=load("res://presentation/daylight_view.gd").new();sky.style=load("res://data/daylight_style.tres");viewport.add_child(sky)
   var source: Image=Image.create(768,384,false,Image.FORMAT_RGBA8);source.fill(Color(0.08,0.2,0.4))
   var clock: RefCounted=load("res://domain/campaign_clock.gd").new()
   clock.is_night=night;clock.remaining=(clock.night_seconds if night else clock.day_seconds)*0.5
   sky.present(clock,ImageTexture.create_from_image(source),Rect2(Vector2.ZERO,Vector2(size)),true)
   await process_frame;await RenderingServer.frame_post_draw
   var pixels: Image=viewport.get_texture().get_image()
   var expected: Color=Color(0.72,0.84,0.89) if night else Color(1,0.93,0.65)
   var low: Vector2i=size;var high: Vector2i=Vector2i.ZERO;var count: int=0
   for y: int in range(size.y):
    for x: int in range(size.x):
     var c: Color=pixels.get_pixel(x,y)
     if absf(c.r-expected.r)<0.008 and absf(c.g-expected.g)<0.008 and absf(c.b-expected.b)<0.008:
      low=low.min(Vector2i(x,y));high=high.max(Vector2i(x,y));count+=1
   var extent: Vector2i=high-low+Vector2i.ONE
   var okay: bool=count>30 and absi(extent.x-extent.y)<=2
   if not okay:failures+=1
   print("PASS: " if okay else "FAIL: ","moon" if night else "sun"," viewport=",size," visible extent=",extent)
   pixels.save_png(output+"-%dx%d-%s.png"%[size.x,size.y,"moon" if night else "sun"])
   viewport.queue_free();await process_frame
 quit(failures)
