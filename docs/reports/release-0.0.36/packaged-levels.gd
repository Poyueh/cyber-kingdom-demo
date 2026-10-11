extends SceneTree
## Exercise actual physics, InputMap, scene wiring and persistence together.
var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
	ProjectSettings.set_setting("campaign/control_preview",1)
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	call_deferred("run_scene")

func check(value: bool, description: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("FAIL: " + description)
	else:
		print("PASS: " + description)

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func frames(count: int) -> void:
	for unused in range(count):
		await physics_frame

const Voyage=preload("res://application/star_voyage.gd")
const NAMES: Array[String]=["forest","desert","frost","swamp","volcanic","storm","void"]
func click(button: Button) -> void:
	await frames(2)
	var at: Vector2=root.get_final_transform()*button.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event: InputEventMouseButton=InputEventMouseButton.new()
		event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
func clear_world(game: Node) -> void:
	for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
	game.sim.raiders.clear();game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
	game.sim.frontier.city_level=1;game.sim.survival.armed=true;game.sim.advance(0.1,30)
	game.sim.planet.claim_core();game.sim.planet.rocket_ready=true;game.knight.position.x=-730
class Search extends RefCounted:
	## Exhaustive button sequences, independent of layout generation. Never used by gameplay.
	static func actions(mechanism: RefCounted) -> Array[int]:
		if mechanism.kind==3:return [0,1,2]
		var saved: Dictionary=mechanism.capture();var progress: int=mechanism.progress()
		var base: int=2 if mechanism.kind==2 else 3
		var limit: int=6 if mechanism.kind==2 else 3
		for length: int in range(1,limit+1):
			for word: int in range(int(pow(base,length))):
				mechanism.restore(saved,progress)
				var remaining: int=word;var path: Array[int]=[];var accepted: bool=true
				for step: int in range(length):
					var action: int=remaining%base;remaining=int(remaining/base)
					path.append(action)
					if not mechanism.activate(action,0):accepted=false;break
				if mechanism.kind==2:path.append(2);accepted=mechanism.activate(2,0) and accepted
				if accepted and mechanism.progress()==3:
					mechanism.restore(saved,progress);return path
		mechanism.restore(saved,progress)
		return []
	static func next_tick(mechanism: RefCounted, station: int, now: int) -> int:
		if mechanism.kind!=3:return now
		# Select the middle of a visible opening, leaving margin for input frames.
		var center: int=int(mechanism.window/2)
		return now+posmod(center-mechanism.phase(station,now),mechanism.period)
func touch(index: int, at: Vector2, down: bool) -> void:
	var event: InputEventScreenTouch=InputEventScreenTouch.new();event.index=index;event.position=at;event.pressed=down
	root.push_input(event,true);Input.flush_buffered_events()
func swipe(index: int, at: Vector2) -> void:
	var event: InputEventScreenDrag=InputEventScreenDrag.new();event.index=index;event.position=at
	root.push_input(event,true);Input.flush_buffered_events()
func capture(game: Node, name: String) -> void:
	game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
	game.view.present(game.sim,game.knight.position.x);game._water.present(game.sim);game._sunbeams.present(game.sim)
	await frames(4)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("/tmp/cyber-v36-packaged-levels")
	game.get_viewport().get_texture().get_image().save_png("/tmp/cyber-v36-packaged-levels/"+name+".png")
func press(game: Node, station: int, mobile: bool) -> void:
	var site: RefCounted=game.sim.trials.sites[0]
	game.knight.position=Vector2(site.positions[station],430);game.knight.velocity=Vector2.ZERO
	game._physics_process(1.0/30)
	if mobile:
		touch(12,Vector2(200,220),true);swipe(12,Vector2(200,280));touch(12,Vector2(200,280),false)
	else:key(KEY_E,true);key(KEY_E,false)
	game._physics_process(1.0/30);await frames(2)
func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	game._map_seed=416;game._seed_initialized=true
	root.add_child(game);await frames(10);game.set_physics_process(false)
	check(game.sim.frontier.regions.size()==14 and game.sim.trials.sites.size()==1,"export contains the authored forest layout")
	check(game.sim.mount_quest.enabled,"export retains the mechanical steed expedition")
	game.sim.spirit.opening_finished=true
	for region: Dictionary in game.sim.frontier.regions:region.discovered=true
	var forest: RefCounted=game.sim.trials.sites[0]
	for station: int in forest.order:await press(game,station,false)
	check(forest.progress==3,"exported forest shrine solves through keyboard input")
	game.knight.position=Vector2(forest.x,430);game._physics_process(1.0/30)
	check(game.sim.modules.found.has("arc"),"exported forest shrine awards Arc Burst")
	for relic: RefCounted in game.sim.modules.relics:
		if relic.id=="lance":game.knight.position=Vector2(relic.x,430);game._physics_process(1.0/30)
	check(game.sim.modules.found.has("lance"),"exported forest exploration awards the lance without a second puzzle")
	clear_world(game)
	for planet: int in [1,3,2,4,5,6]:
		game.sim.planet.launch_requested=true;game._star_travel.observe()
		await click(game._star_travel.map._buttons[planet]);await click(game._star_travel.map._launch);await frames(3)
		check(game.journey.current==planet,"actual voyage reaches puzzle world "+str(planet))
		game._arrival_banner.hide();game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
		game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
		for region: Dictionary in game.sim.frontier.regions:region.discovered=true
		var site: RefCounted=game.sim.trials.sites[0];var m: RefCounted=site.mechanism
		game.knight.position=Vector2(site.positions[1],430);game._physics_process(1.0/30)
		game.hud.control_mode=1 if planet%2==0 else 2
		TranslationServer.set_locale("zh_TW")
		# Let the actual 1.8-second exploration reveal finish before judging pixels.
		for i: int in range(65):game._physics_process(1.0/30)
		await capture(game,"world-"+str(planet))
		if planet in [1,2]:
			for locale: String in ["zh_CN","en"]:
				TranslationServer.set_locale(locale);await capture(game,"world-%d-%s"%[planet,locale])
				check(not game.tr("ruin.balance.hint").begins_with("ruin."),"mechanism guidance translates in "+locale)
			TranslationServer.set_locale("zh_TW")
		if planet==2:
			game.knight.position=Vector2(site.positions[0],430);game._physics_process(1.0/30)
			await capture(game,"frost-clearing")
			check(game.sim.context(game.knight.position.x).id=="trial","camp-clearing device accepts actual scene interactions")
		var amount: int=game.sim.pouch.amount
		var actions: Array[int]=Search.actions(m)
		check(not actions.is_empty(),"visible generated devices provide a solvable route")
		for i: int in range(actions.size()):
			var tick: int=Search.next_tick(m,actions[i],roundi(game.sim.workforce.elapsed*30))
			game.sim.workforce.elapsed=float(tick)/30
			await press(game,actions[i],planet%2==0)
		check(site.progress==3,"keyboard or mobile gesture solves this family in the real scene")
		check(game.sim.pouch.amount==amount,"mechanism interactions do not accidentally throw crystals")
		game.knight.position=Vector2(site.x,430);game._physics_process(1.0/30)
		check(game.sim.modules.equipped==site.id,"scene awards the expected planet module")
		if planet==5:
			game.paused=true
			var phase: int=m.phase(0,roundi(game.sim.workforce.elapsed*30))
			for i: int in range(30):game._physics_process(0.5)
			check(m.phase(0,roundi(game.sim.workforce.elapsed*30))==phase,"pause freezes the visible pulse needle")
			game.paused=false
		clear_world(game);game.journey.observe(game.sim)
	var packet: Dictionary=game.journey.capture(game.sim,{"x":game.knight.position.x,"y":430.0,"vx":0.0,"vy":0.0})
	check(not Voyage.restore(packet).is_empty(),"all six solved worlds remain valid in a real voyage save")
	game.queue_free();await frames(2)
	print("Planet ruin scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
