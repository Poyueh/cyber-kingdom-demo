extends SceneTree
var failures:int=0
var checks:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1
 print("PASS: " if ok else "FAIL: ",label)
func run()->void:
 var visual=load("res://scenes/knight_visual.tscn").instantiate()
 visual.appearance=load("res://data/hero_v005_appearance.tres")
 root.add_child(visual)
 for unarmed:bool in [false,true]:
  visual.reset_pose();visual.unarmed=unarmed
  var p:Dictionary={"alive":true,"hp":100,"shield":0,"facing":1,"moving":false,"grounded":true,"invulnerable":false,"attack_progress":1.0,"horizontal_speed":0.0}
  visual.present(p,0.1)
  p.moving=true;p.horizontal_speed=165.0;visual.present(p,1.0/60)
  check(visual.locomotion_transition.visible,"start uses full-body weight transfer")
  var tex:Texture2D=visual.locomotion_transition.texture
  visual.present(p,0)
  check(visual.locomotion_transition.texture==tex,"pause holds transition drawing")
  for i:int in range(20):visual.present(p,1.0/60)
  var drawing:AtlasTexture=visual._unarmed.texture if unarmed else visual.sprite_frames.get_frame_texture(visual.animation,visual.frame)
  check(drawing.atlas.resource_path.ends_with("gait-run-unarmed.png" if unarmed else "gait-run.png"),"ordinary movement is running")
  p.facing=-1;p.horizontal_speed=-165.0;visual.present(p,1.0/60)
  check(visual.locomotion_transition.visible and not visual.locomotion_transition.flip_h,"reversal starts from prior facing with a planted pivot")
  for i:int in range(20):visual.present(p,1.0/60)
  p.moving=false;p.horizontal_speed=0;visual.present(p,1.0/60)
  check(visual.locomotion_transition.visible,"stop settles weight before idle")
  p.attack_progress=0.5;p.combo_step=1;visual.present(p,1.0/60)
  check(not visual.locomotion_transition.visible,"attack immediately interrupts cosmetic transition")
  p.attack_progress=1;p.moving=true;p.horizontal_speed=69.3;visual.tired_walk=true
  for i:int in range(20):visual.present(p,1.0/60)
  drawing=visual._unarmed.texture if unarmed else visual.sprite_frames.get_frame_texture(visual.animation,visual.frame)
  check(drawing.atlas.resource_path.ends_with("gait-tired-unarmed.png" if unarmed else "gait-tired.png"),"walking is reserved for fatigue")
  visual.tired_walk=false
 visual.queue_free();await process_frame
 print("Weighted motion: %d checks, %d failures"%[checks,failures]);quit(failures)
