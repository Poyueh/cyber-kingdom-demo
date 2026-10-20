extends SceneTree
## Native visual review, not a replacement for device playtesting.
const STEP: float=1.0/30.0
const OUT: String="res://test-results/motorcycle/"
var game: Node
var frame_index: int=0
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	ProjectSettings.set_setting("campaign/control_preview",2)
	ProjectSettings.set_setting("distribution/edition","demo" if "--demo" in OS.get_cmdline_user_args() else "full")
	Engine.max_fps=30
	call_deferred("run")
func tick(count: int) -> void:
	for i: int in range(count):
		game.paused=false
		game._physics_process(STEP)
		await physics_frame
func shot(label: String) -> void:
	game.knight.get_node("Camera2D").reset_smoothing()
	game.knight.get_node("Camera2D").force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func key(code: int, down: bool) -> void:
	var event: InputEventKey=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	game=load("res://scenes/frontier.tscn").instantiate()
	game._guided_campaign=true
	game.campaign_save_path="";game.audio_preferences_path=""
	game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
	root.add_child(game)
	for i: int in range(8):await physics_frame
	game.set_physics_process(false)
	var sim: RefCounted=game.sim
	sim.interact(sim.world.sites.hall,"hall");await tick(170)
	sim.frontier.city_level=3;sim.core_loop.income=6;sim.core_loop.stage=5
	sim.core_loop.checkpoint_index=0;sim.core_loop.checkpoint_pending=0
	sim.clock.survived=2;sim.clock.day=3;sim.clock.remaining=sim.clock.day_seconds*0.7
	sim.pouch.amount=30
	sim.command.used.assign(preload("res://application/feature_lessons.gd").IDS)
	for region: Dictionary in sim.frontier.regions:region.discovered=true
	var q: RefCounted=sim.mount_quest
	q.rotations.assign([1,2]);q.recover();q.restore_stable(roundi(sim.workforce.elapsed*30))
	game.knight.position=Vector2(q.stable_x,430)
	await tick(300)
	await tick(5);await shot("garage-riding")
	q.toggle();await tick(5);await shot("garage-parked")
	q.toggle();await tick(5)
	key(KEY_D,true)
	for i: int in range(30):
		await tick(1);await shot("ride-%03d"%frame_index);frame_index+=1
	key(KEY_D,false);await tick(8);await shot("stop")
	key(KEY_A,true)
	for i: int in range(20):
		await tick(1);await shot("ride-%03d"%frame_index);frame_index+=1
	key(KEY_A,false);await tick(8)
	key(KEY_D,true);await tick(1);key(KEY_D,false);await tick(1)
	for attack: int in range(3):
		key(KEY_J,true);await tick(1);key(KEY_J,false)
		for i: int in range(16):
			await tick(1);await shot("attack-%d-%02d"%[attack,i])
	await shot("stopped")
	game.knight.position=Vector2(q.ruin_x,430);await tick(4);await shot("cradle")
	# The same composed scene exposes touch controls in the review.
	game.hud.control_mode=1;await tick(4);await shot("touch")
	print("Motorcycle native review complete: ",OUT)
	game.queue_free();await process_frame;quit()
