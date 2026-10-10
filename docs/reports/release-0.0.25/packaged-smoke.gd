extends SceneTree
var game: Node
var failures: int=0
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run")
func check(value: bool, message: String) -> void:
 if not value:failures+=1;push_error(message)
 else:print("PASS: "+message)
func frames(count: int) -> void:
 for tick: int in range(count):await physics_frame
func key(code: int, pressed: bool) -> void:
 var event: InputEventKey=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed
 Input.parse_input_event(event);Input.flush_buffered_events()
func run() -> void:
 check(not ResourceLoader.exists("res://tests/test_supply_guidance_scene.gd"),"runtime uses exported content, not test sources")
 game=load("res://scenes/frontier.tscn").instantiate();game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(8);game.set_physics_process(false)
 game.sim.pouch.amount=0;game.knight.position=Vector2(30,430)
 game._physics_process(1.0/30)
 check(game.hud.guide_view.hint.get("kind")=="camp","packaged empty-pouch opening points to free camp")
 key(KEY_E,true);key(KEY_E,false);game._physics_process(1.0/30)
 check(game.sim.can_wield_sword() and game.sim.frontier.city_level==1,"packaged E draws sword and lights camp")
 var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v24-compat/save.json"))
 var restored: Dictionary=codec.restore(old)
 check(not restored.is_empty(),"actual v0.0.24 checkpoint loads inside released runtime")
 if not restored.is_empty():
  var sim: RefCounted=restored.session
  var guide: Script=load("res://application/campaign_guide.gd")
  check(guide.next(sim,30).get("key")=="hunt_tools","packaged advice counts saved installments")
  check(sim.interact(sim.world.sites.hunt_tools,"hunt_tools") and sim.world.tools.bow==1,"saved bow can be completed")
  check(guide.funding_hint(sim,30).get("kind")=="resident_income","packaged income query points to known carrier")
  check(not codec.restore(codec.capture(sim,restored.config,restored.body)).is_empty(),"packaged continuation can be saved again")
 game.sim.planet.cleared=true;game.sim.planet.claim_core();game.sim.pouch.amount=1
 game.sim.world.people[0].role="engineer";game.sim.world.people[0]["crystals"]=4
 game.sim.spirit.summoned=true
 check(game.sim.spirit.advice(game.sim,30).get("kind")=="resident_income","post-dragon guidance shares the funding rule")
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale)
  check(not game.tr("guide.income").begins_with("guide."),"packaged income translation "+locale)
 game.audio.enabled=false;game.audio.stop();game.queue_free();await frames(2)
 print("PACKAGED SUPPLY GUIDANCE FAILURES: ",failures);quit(0 if failures==0 else 1)
