extends SceneTree
var game: Node
var output: String="/tmp/cyber47-presentation"
var checks: int=0
var failures: int=0
var results: Array=[]
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 ProjectSettings.set_setting("campaign/control_preview",1)
 call_deferred("run")
func check(value: bool, detail: String) -> void:
 checks+=1
 if not value:failures+=1;printerr("FAIL: "+detail)
func tick(count: int) -> void:
 for i: int in range(count):await physics_frame
func body_state() -> Array:
 var visual: Node=game.knight.visual
 var bodies: Array=[]
 if visual.visible and visual.self_modulate.a>0.5:bodies.append([visual.animation,visual.frame])
 for child: Node in visual.get_children():
  if child is Sprite2D and child.visible and child.modulate.a>0.5:
   var tex: AtlasTexture=child.texture
   check(Rect2(Vector2.ZERO,tex.atlas.get_size()).encloses(tex.region),"visible pose stays inside atlas")
   bodies.append([child.name,str(tex.region)])
 return bodies
func show_pose(label: String, armed: bool, mounted: bool, facing: int, extra: Dictionary={}) -> void:
 var visual: Node=game.knight.visual
 visual.reset_pose();visual.unarmed=not armed;visual.mounted=mounted
 visual.equipped_module="lance";visual.breathing=false
 var pose: Dictionary={"alive":true,"hp":100,"shield":0,"facing":facing,"moving":false,"grounded":true,"invulnerable":false,"attack_progress":1.0,"horizontal_speed":0.0}
 pose.merge(extra,true)
 visual.present(pose,0.1)
 if label.begins_with("hurt"):visual.damage_serial+=1;visual.present(pose,0.1)
 if label.begins_with("death"):
  for i in range(4):visual.present(pose,0.1)
 if label.begins_with("rest"):visual.breathing=true;visual.present(pose,1.0)
 var before: Array=body_state()
 check(before.size()==1,"one full body in "+label)
 visual.present(pose,0)
 check(body_state()==before,"zero game time freezes "+label)
 game._lantern.present(game.sim,game.knight)
 await tick(2);RenderingServer.force_draw()
 root.get_texture().get_image().save_png(output.path_join(label+".png"))
 results.append({"pose":label,"bodies":before})
func run() -> void:
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
 DirAccess.make_dir_recursive_absolute(output)
 game=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await tick(10)
 game.set_physics_process(false);game.knight.set_physics_process(false)
 game.sim.frontier.city_level=3;game.sim.survival.armed=true
 game.sim.spirit.expires_tick=0;game.sim.spirit.opening_finished=true
 game.knight.position=Vector2(30,430);game._sync_knight_equipment()
 var camera: Camera2D=game.knight.get_node("Camera2D")
 camera.zoom=Vector2(3,3);camera.position=Vector2(0,-28);camera.reset_smoothing();camera.force_update_scroll()
 game.hud.hide();game.view.present(game.sim,30)
 for facing: int in [-1,1]:
  for armed: bool in [false,true]:
   var suffix: String="-%d-%s"%[facing,str(armed)]
   await show_pose("idle"+suffix,armed,false,facing)
   await show_pose("run"+suffix,armed,false,facing,{"moving":true,"horizontal_speed":206.0})
   await show_pose("hurt"+suffix,armed,false,facing)
   await show_pose("death"+suffix,armed,false,facing,{"alive":false,"hp":0})
   await show_pose("rest"+suffix,armed,false,facing)
   await show_pose("mounted"+suffix,armed,true,facing,{"moving":true,"horizontal_speed":206.0})
   await show_pose("mounted-idle"+suffix,armed,true,facing)
   await show_pose("rest-mounted"+suffix,armed,true,facing)
  for step: int in [1,2,3]:
   await show_pose("cut-%d-%d"%[step,facing],true,false,facing,{"attack_progress":0.57,"combo_step":step})
   await show_pose("rider-cut-%d-%d"%[step,facing],true,true,facing,{"attack_progress":0.57,"combo_step":step})
 game.restart();await tick(2)
 check(not game.knight.visual.mounted and not game.knight.visual.fatigue.visible,"restart clears rider and fatigue presentation")
 var file: FileAccess=FileAccess.open(output.path_join("evidence.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"assertions":checks,"failures":failures,"poses":results},"\t"));file.close()
 game.queue_free();await tick(3)
 print("Hero presentation assertions: %d; failures: %d"%[checks,failures]);quit(0 if failures==0 else 1)
