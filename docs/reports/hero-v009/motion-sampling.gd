extends SceneTree
var failures: int=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var actor: Node=load("res://scenes/knight_visual.tscn").instantiate()
 actor.appearance=load("res://data/hero_v005_appearance.tres")
 root.add_child(actor)
 for unarmed: bool in [false,true]:
  for speed: float in [165.0,321.75]:
   actor.reset_pose();actor.unarmed=unarmed
   var pose: Dictionary={"alive":true,"hp":100,"shield":0,"facing":1,"moving":true,"horizontal_speed":speed,"grounded":true,"invulnerable":false,"attack_progress":1.0}
   var previous: int=-1;var held: int=0;var longest: int=0
   for tick: int in range(120):
    actor.present(pose,1.0/60.0)
    var index: int=actor.frame
    if unarmed:
     var region: Rect2=actor._unarmed.texture.region
     index=int(region.position.y/96)*actor.appearance.stride_columns+int(region.position.x/128)
    held=held+1 if index==previous else 1
    longest=maxi(longest,held);previous=index
   var limit: int=6 if speed<240 else 4
   if longest>limit:failures+=1
   print("%s speed=%s longest unchanged drawing=%d ticks (limit %d): %s"%["unarmed" if unarmed else "armed",speed,longest,limit,"PASS" if longest<=limit else "FAIL"])
 actor.queue_free();await process_frame
 print("Motion sampling: 4 checks, %d failures"%failures)
 quit(1 if failures else 0)
