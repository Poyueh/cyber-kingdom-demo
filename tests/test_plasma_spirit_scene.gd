extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var guide: Node2D=load("res://presentation/campaign_guide_view.gd").new()
 root.add_child(guide);await frames(2)
 var area: Rect2=Rect2(0,0,960,540)
 # A wide interaction caption crosses the usual hover band while running through town.
 guide.reserved_regions.append(Rect2(230,180,500,250))
 var hidden: int=0
 for tick: int in range(180):
  var world_x: float=-400.0+tick*5.0
  guide.present({"kind":"camp","x":800.0,"y":430.0,"action":"move"},area,world_x,Rect2(),false)
  guide.track(Vector2(480,400),tick/30.0)
  if not guide._art_clear:hidden+=1
 check(hidden==0,"running past a wide caption repositions the companion instead of blinking out")
 check(guide._guide_label.mouse_filter==Control.MOUSE_FILTER_IGNORE,"companion text does not capture input")
 guide.free();print("Plasma spirit: %d assertions; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
