extends "res://tests/test_star_voyage_scene.gd"
var _heard: Array[String] = []
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
	DirAccess.make_dir_recursive_absolute("res://test-results/voyage-progress")
	game.get_viewport().get_texture().get_image().save_png("res://test-results/voyage-progress/"+name+".png")
func ready_core(game: Node) -> void:
	for gate: Dictionary in game.sim.mission.rifts:gate.sealed=true
	game.sim.raiders.clear();game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
	game.sim.frontier.city_level=1;game.sim.survival.armed=true
	game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
	game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
	game.sim.advance(0.1,30);game.paused=false
	game.knight.position=Vector2(-185,430);game.knight.velocity=Vector2.ZERO
	game._physics_process(1.0/30);game._arrival_banner.hide()
	_heard.clear()
func claim(game: Node, mobile: bool) -> void:
	game.hud.control_mode=1 if mobile else 2
	game._physics_process(1.0/30)
	if mobile:
		touch(12,Vector2(200,220),true);swipe(12,Vector2(200,280));touch(12,Vector2(200,280),false)
	else:key(KEY_E,true);key(KEY_E,false)
	game._physics_process(1.0/30);await frames(2)
func inspect_chart(game: Node) -> void:
	var expected: Dictionary=preload("res://application/voyage_progress.gd").read(game.journey,game.sim,0)
	for locale: String in ["zh_TW","zh_CN","en"]:
		TranslationServer.set_locale(locale)
		game._star_travel.open_chart(true)
		var map: Node=game._star_travel.map
		for id: int in range(7):
			await click(map._buttons[id])
			check(map._panel.size.x<=960 and map._panel.size.y<=540,"every world card fits: "+locale+" / "+str(id))
		await click(map._buttons[0])
		check(map._milestones.report==expected,"chart shows current or archived world without rebuilding it: "+locale)
		await capture(game,"chart-"+locale)
		check(map._panel.size.x<=960 and map._panel.size.y<=540,"full milestone chart fits phone viewport: "+locale)
		check(not map._milestones._titles[0].text.begins_with("milestone."),"milestone names translated: "+locale)
		await click(map._buttons[6])
		check(map._milestones.report=={"known":false} and map._milestones._unknown.visible,"unvisited card does not disclose hidden counts")
		check(map._milestones._rows.all(func(row: HBoxContainer)->bool:return not row.visible),"unknown world's three progress rows remain hidden")
		game._star_travel.close()
	TranslationServer.set_locale("zh_TW")
func verify_pause_and_restore(game: Node) -> void:
	var ceremony: Node=game._star_travel.liberation
	var age: float=ceremony._age
	game.paused=true
	for i: int in range(10):game._physics_process(0.25)
	check(not ceremony.visible and ceremony._age==age,"pause hides and freezes the ceremony")
	game.paused=false;game._physics_process(1.0/30)
	check(ceremony.visible,"resume restores the remaining celebration")
	var state: Dictionary=game.journey.capture(game.sim,{"x":-185.0,"y":430.0,"vx":0.0,"vy":0.0})
	var restored: Dictionary=Voyage.restore(JSON.parse_string(JSON.stringify(state)))
	check(not restored.is_empty(),"actual multiworld save restores after reclaiming core")
	game._apply_restored(restored);game.paused=false;game._physics_process(1.0/30)
	check(not ceremony.visible,"loading a previously claimed core does not replay its ceremony")
func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path="";game._map_seed=416;game._seed_initialized=true
	root.add_child(game);await frames(10);game.set_physics_process(false)
	game.audio.cue_requested.connect(func(kind: String):_heard.append(kind))
	check(game._star_travel.map.find_child("Milestones",true,false)!=null,"real map contains achievements")
	check(game._star_travel.find_child("Liberation",true,false)!=null,"real voyage contains the claim ceremony")
	check(not game._star_travel.liberation.visible,"fresh journey does not invent a celebration")
	for planet: int in [0,1,3,2,4,5,6]:
		if planet>0:
			game.sim.planet.rocket_ready=true;game.knight.position.x=-730
			game.sim.planet.launch_requested=true;game._star_travel.observe()
			await click(game._star_travel.map._buttons[planet]);await click(game._star_travel.map._launch);await frames(3)
			game._arrival_banner.hide()
		check(game.journey.current==planet,"real route reaches world "+str(planet))
		ready_core(game)
		var amount: int=game.sim.pouch.amount
		await claim(game,planet%2==1)
		check(game.sim.planet.core_claimed,"keyboard or downward touch swipe claims the earned core")
		check(game.sim.pouch.amount==amount,"free core claim does not drop or consume a crystal")
		check(_heard.count("victory")==1,"core or final victory plays one actual sound cue")
		for i: int in range(20):game._physics_process(1.0/30)
		check(game._star_travel.liberation.visible==(planet!=6),"seventh core yields to the terminal victory instead of overlapping it")
		if planet==0:
			check(game._star_travel.liberation._routes==[1,2],"forest ceremony reveals only desert and frost routes")
			for locale: String in ["zh_TW","zh_CN","en"]:
				TranslationServer.set_locale(locale);game._star_travel.observe()
				await capture(game,"liberation-"+locale)
				check(not game._star_travel.liberation.caption.text.contains("planet."),"liberation caption translated: "+locale)
			await verify_pause_and_restore(game)
		if planet==1:
			await inspect_chart(game)
			for i: int in range(200):game._physics_process(1.0/30)
			check(not game._star_travel.liberation.visible,"ceremony expires and does not leave a permanent HUD")
		check(_heard.count("victory")==1,"continued presentation never replays the claim sound")
	check(game.sim.mission.outcome=="victory","seven actual core interactions still complete the journey")
	game.audio.enabled=false;game.audio.stop();game.queue_free();await frames(3)
	print("Voyage progress scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
