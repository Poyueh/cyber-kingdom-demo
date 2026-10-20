extends Node
## Isolated full-scene diagnostic; protected actors keep the stress session alive.
const DURATION: float = 1920.0
var game: Node
var elapsed: float = 0.0
var report_at: float = 0.0
var restore_at: float = 300.0
var spawn_at: float = 5.0
var cue_at: float = 0.0
var accepted: int = 0
var restores: int = 0
var failures: int = 0
var moving: int = 0
var attacking: bool = false
var button: Button
var started: int = 0
var active: bool = false
func _ready() -> void:
	process_physics_priority = -100
	var layer := CanvasLayer.new();add_child(layer)
	button=Button.new();button.text="Start 32-minute full-scene soak (isolated save)";button.position=Vector2(20,20);button.size=Vector2(700,80);layer.add_child(button)
	button.pressed.connect(begin)
	set_physics_process(false)
func begin() -> void:
	button.hide()
	Engine.physics_ticks_per_second=30
	game=load("res://scenes/frontier.tscn").instantiate()
	game._guided_campaign=true
	game.campaign_save_path="user://diagnostic_%d.json"%Time.get_ticks_msec()
	game.audio_preferences_path=""
	game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
	add_child(game)
	game.sim.interact(game.sim.world.sites.hall,"hall")
	game.sim.frontier.city_level=3
	game.sim.core_loop.income=6;game.sim.core_loop.stage=5;game.sim.core_loop.checkpoint_index=0;game.sim.core_loop.checkpoint_pending=0
	game.sim.clock.survived=2;game.sim.clock.day=3
	game.sim.command.used.assign(preload("res://application/feature_lessons.gd").IDS)
	for region: Dictionary in game.sim.frontier.regions:region.discovered=true
	for id: String in ["wall","wall_left"]:
		game.sim.world.walls[id].level=2;game.sim.world.walls[id].hp=game.sim.world.wall_max_hp(2)
	for index: int in range(game.sim.world.people.size()):game.sim.world.people[index].role=["hunter","guard","engineer"][index%3]
	game.audio.cue_requested.connect(func(_kind):accepted+=1)
	started=Time.get_ticks_msec();active=true;set_physics_process(true)
func key(code: int,down: bool) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=down
	get_viewport().push_input(event,true);Input.flush_buffered_events()
func _physics_process(seconds: float) -> void:
	if not active:return
	elapsed=float(Time.get_ticks_msec()-started)/1000.0
	var sim: RefCounted=game.sim
	# Test-only keepalive, never exported in the game: exercise damage without ending the run.
	sim.hero.hp=sim.hero.stats.max_hp;sim.mission.core_hp=sim.mission.core_max_hp;sim.mission.outcome="active";sim.pouch.amount=20
	game.paused=false;game.audio.suspended=false
	var direction: int=1 if int(elapsed/12.0)%2==0 else -1
	if game.knight.position.x>sim.world.sites.hall+1700:direction=-1
	if game.knight.position.x<sim.world.sites.hall-1700:direction=1
	if direction!=moving:
		if moving!=0:key(KEY_D if moving>0 else KEY_A,false)
		moving=direction;key(KEY_D if moving>0 else KEY_A,true)
	var attack: bool=fmod(elapsed,0.8)<0.1
	if attack!=attacking:key(KEY_J,attack);attacking=attack
	if elapsed>=spawn_at:
		spawn_at+=20.0
		if sim.raiders.size()<12:
			var enemy: Dictionary=sim._spawn_raider();enemy.x=game.knight.position.x+110.0*direction;enemy["side"]=direction;enemy["direction"]=-float(direction);enemy["exit_x"]=sim.mission.entry_x(direction)+direction*70.0;sim.raiders.append(enemy)
	if elapsed>=cue_at:
		cue_at+=0.25
		game.audio.request(["footstep","work_chop","bow_shot","hit"][int(elapsed*4)%4])
	if elapsed>=restore_at:
		restore_at+=300.0
		if game.save_manual_campaign() and game.load_manual_campaign():restores+=1
		else:failures+=1
		game._resume_from_menu();moving=0;attacking=false
	if elapsed>=report_at or elapsed>=DURATION:
		report_at+=30.0
		var row: Dictionary={"mode":"campaign","elapsed":snappedf(elapsed,0.1),"simulation_seconds":sim.workforce.elapsed,"day":sim.clock.day,"accepted":accepted,"restores":restores,"save_status":game.progress.status,"save_error":game.progress.last_error,"failures":failures,"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,"peak_db":AudioServer.get_bus_peak_volume_left_db(0,0),"fps":Performance.get_monitor(Performance.TIME_FPS),"enemies":sim.raiders.size(),"effects":sim.effects.size(),"drops":sim.pouch.drops.size(),"complete":elapsed>=DURATION}
		print("WEB_SOAK ",JSON.stringify(row))
		if OS.has_feature("web"):JavaScriptBridge.eval("window.CKSoak.receive("+JSON.stringify(row)+")",true)
	if elapsed>=DURATION:
		active=false;game.set_physics_process(false);game.audio.stop()
		key(KEY_A,false);key(KEY_D,false);key(KEY_J,false)
		button.text="Soak complete — inspect report";button.show();button.disabled=true
