extends "res://tests/test_scene.gd"
func settle() -> void:
	await frames(8);await process_frame;await process_frame
func click(button: Control, touch: bool=false) -> void:
	for down: bool in [true,false]:
		var event: InputEvent
		if touch:
			var finger: InputEventScreenTouch=InputEventScreenTouch.new()
			finger.index=34;finger.position=button.get_global_rect().get_center();finger.pressed=down;event=finger
		else:
			var mouse: InputEventMouseButton=InputEventMouseButton.new()
			mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=button.get_global_rect().get_center();mouse.pressed=down;event=mouse
		root.push_input(event,true);Input.flush_buffered_events();await frames(2)
	await settle()
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/journey-pacing")
	root.get_texture().get_image().save_png("res://test-results/journey-pacing/"+name+".png")
func run_scene() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",true)
	set_meta("campaign_prologue_seen",true)
	var folder: String="user://test_pacing_%d"%Time.get_ticks_usec()
	var language_path: String="user://test_pacing_language_%d.cfg"%Time.get_ticks_usec()
	var language: Node=root.get_node("GameLanguage")
	language.preferences=load("res://infrastructure/language_preferences.gd").new(language_path)
	language.choose("zh_TW")
	var menu: Node=load("res://scenes/start_menu.tscn").instantiate()
	menu.campaigns_directory=folder;menu.legacy_path="";menu.audio_preferences_path=""
	root.add_child(menu);current_scene=menu
	await settle()
	await click(menu.view.new_button)
	check(current_scene==menu,"new game offers a pace choice before creating a journey")
	if current_scene!=menu:quit(1);return
	var picker: Control=menu.view.pace_picker
	check(picker.visible,"title offers a visible pace picker")
	check(menu.catalog.entries().is_empty(),"viewing choices allocates no save")
	await click(picker.choices[1],true)
	check(picker.selected==1,"actual touch selects the settler pace")
	for locale: String in ["zh_TW","zh_CN","en"]:
		language.choose(locale);await settle()
		check(not picker.description.text.begins_with("journey."),"pace description is translated: "+locale)
		check(root.get_visible_rect().encloses(picker.get_global_rect()),"all pace controls fit the viewport: "+locale)
		check(picker.selected==1,"changing language retains choice: "+locale)
		await shot(locale)
	await click(picker.back,true)
	check(menu.view.new_button.visible and menu.catalog.entries().is_empty(),"cancel returns home without a new record")
	await click(menu.view.new_button)
	check(picker.selected==0,"fresh selection recommends expedition")
	await click(picker.choices[2]);await click(picker.confirm)
	var game: Node=current_scene
	check(game.name=="Frontier","confirmation launches the actual playable scene")
	if game.name!="Frontier":quit(1);return
	game.set_physics_process(false)
	var path: String=game.campaign_save_path
	check(FileAccess.file_exists(path),"confirmed pace has its own saved journey")
	check(game._campaign_config.journey_style==2 and game.sim.clock.day_seconds==160.0,"actual scene uses siege daylight")
	check(game.sim.night_pressure.count_for(5)==17,"actual scene uses siege reinforcements")
	check(game.journey.configs.all(func(config: Dictionary)->bool:return config.journey_style==2),"launch carries chosen pace through seven worlds")
	for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
	game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
	game.sim.frontier.city_level=1;game.sim.survival.armed=true
	game.sim.frontier.nodes[0].collected=true;game.sim.frontier.nodes[0].delivered=true
	game.sim.advance(0.1,30);game.sim.planet.claim_core();game.sim.planet.rocket_ready=true
	var trip: Dictionary=game.journey.prepare(game.sim,{"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0},1)
	check(not trip.is_empty(),"manual checkpoint scenario reaches a second planet through the voyage")
	if trip.is_empty():quit(1);return
	game._apply_restored(trip)
	var configured: Array[Dictionary]=game.journey.configs.duplicate(true)
	check(game.save_manual_campaign(),"paced journey can make a manual checkpoint")
	game.return_to_title();await settle();menu=current_scene
	menu.catalog=load("res://infrastructure/campaign_catalog.gd").new(folder,"")
	menu.show_records();await settle()
	check(menu.rows.size()==2 and menu.rows.all(func(row: Dictionary)->bool:return row.pace==2),"record picker identifies the journey's pace")
	await shot("record")
	var manual: int=0 if menu.rows[0].manual else 1
	menu.select_record(manual);await settle();game=current_scene
	game.set_physics_process(false)
	check(game._campaign_config.journey_style==2 and game.sim.clock.day_seconds==configured[1].day_seconds,"resume keeps saved pace instead of the menu default")
	check(game.campaign_save_path!=path,"manual checkpoint forks instead of overwriting the automatic journey")
	check(load("res://application/campaign_checkpoint_rules.gd").same(game.journey.configs,configured),"manual fork preserves the resolved pace of all seven planets")
	check(game.journey.current==1 and game.journey.planets[0].planet.core_claimed,"manual fork keeps current planet and previous dragon core")
	check(game.journey.planets[0].campaign.nodes[0].collected,"manual fork preserves previously collected frontier resources")
	game.restart();game.set_physics_process(false)
	check(game._campaign_config.journey_style==2,"explicit retry retains chosen pace")
	game.queue_free();await process_frame
	if DirAccess.dir_exists_absolute(folder):
		for name: String in DirAccess.get_files_at(folder):DirAccess.remove_absolute(folder.path_join(name))
		DirAccess.remove_absolute(folder)
	DirAccess.remove_absolute(language_path)
	print("Journey pacing scene assertions: %d; failures: %d"%[assertions,failures])
	quit(0 if failures==0 else 1)
