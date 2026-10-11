extends "res://tests/test_scene.gd"
const Codec = preload("res://application/campaign_snapshot.gd")

func shot(game: Node, name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/settlement-growth")
	game.get_viewport().get_texture().get_image().save_png("res://test-results/settlement-growth/"+name+".png")

func tap(button: Control) -> void:
	var event: InputEventScreenTouch=InputEventScreenTouch.new()
	event.index=46;event.position=button.get_global_rect().get_center();event.pressed=true
	root.push_input(event,true);Input.flush_buffered_events();await frames(2)
	event=InputEventScreenTouch.new();event.index=46;event.position=button.get_global_rect().get_center();event.pressed=false
	root.push_input(event,true);Input.flush_buffered_events();await frames(3)

func upgrade(game: Node) -> void:
	var target: int=game.sim.frontier.city_level+1
	game.knight.position=Vector2(game.sim.world.sites.hall,430)
	await frames(3)
	key(KEY_E,true)
	for i: int in range(150):
		await frames(1)
		if game.sim.frontier.city_level>=target:break
	key(KEY_E,false)
	await frames(42)

func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game);await frames(10)
	game.hud.control_mode=2
	await upgrade(game)
	game.sim.pouch.amount=30
	await upgrade(game)
	check(game.sim.frontier.city_level==2,"actual E investment reaches the second camp stage")
	var growth: Node=game.hud.get_node_or_null("SettlementGrowth")
	check(growth!=null,"a completed camp upgrade has a visible growth presentation")
	if growth!=null:
		check(growth.visible and growth.current_level()==2,"actual upgrade announces the correct new stage")
		check(growth.caption.text==tr("settlement.stage.2"),"the upgrade has a localized title")
		await shot(game,"upgrade-2")
		key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
		var remaining: float=game.sim.clock.remaining
		check(not growth.visible,"pause hides the growth overlay")
		await frames(15)
		check(is_equal_approx(game.sim.clock.remaining,remaining),"reviewing milestones cannot consume the night timer")
		var map_button: Button=game.hud.options_menu.find_child("ExplorationMap",true,false)
		map_button.pressed.emit();await frames(3)
		var atlas: Node=game.hud.exploration_map
		atlas.settlement_tab.pressed.emit();await frames(3)
		check(atlas.settlement_panel.visible and not atlas._chart.visible,"camp tab replaces the map in the existing panel")
		for locale: String in ["zh_TW","zh_CN","en"]:
			TranslationServer.set_locale(locale)
			atlas.present(game.sim,game.knight.position.x)
			atlas.settlement_tab.pressed.emit()
			await frames(4)
			check(not atlas._detail.text.begins_with("settlement."),"camp history is translated: "+locale)
			check(game.hud.safe_rect().encloses(atlas.get_rect()),"camp history fits the safe viewport: "+locale)
			await shot(game,"history-"+locale)
		atlas.settlement_panel.cards[2].pressed.emit();await frames(2)
		check(atlas._detail.text==tr("settlement.requirement"),"unbuilt stage explains the requirement rather than claiming unlocked tools")
		atlas.frontier_tab.pressed.emit();await frames(2)
		check(atlas._chart.visible and not atlas.settlement_panel.visible,"frontier tab restores the existing exploration chart")
		atlas._close.pressed.emit();await frames(2)
		key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
		game.hud.control_mode=1
		game.hud.preview_safe_margins=Vector4(34,4,26,18)
		game.hud._layout()
		game.sim.pouch.amount=30
		await upgrade(game)
		check(game.sim.frontier.city_level==3 and growth.current_level()==3,"later growth supersedes the earlier celebration")
		check(game.sim.world.tools.blade==0,"unlock presentation never supplies free soldiers")
		await shot(game,"upgrade-3-touch")
		key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
		map_button.pressed.emit();await frames(3)
		await tap(atlas.settlement_tab)
		check(atlas.settlement_panel.visible,"real touch input opens the settlement tab")
		check(game.hud.safe_rect().encloses(atlas.get_rect()),"settlement tab fits mobile cutout margins")
		await tap(atlas.settlement_panel.cards[0])
		check(atlas._detail.text==tr("settlement.unlock.1"),"real touch input reviews an earlier unlocked stage")
		await shot(game,"history-touch")
		atlas._close.pressed.emit();await frames(2)
		key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
		game.sim.clock.day=4;game.sim.clock.survived=3;game.sim.clock.remaining=74
		await frames(15)
		check(game.hud.night_watch_view.visible and not growth.caption.visible,"night attack warning takes priority over the celebration caption")
		await frames(420)
		check(not growth.visible,"celebration expires instead of becoming a permanent HUD")
		var body: Dictionary={"x":game.knight.position.x,"y":game.knight.position.y,"vx":0.0,"vy":0.0}
		var packet: Dictionary=Codec.new().capture(game.sim,game._campaign_config,body)
		var restored: Dictionary=Codec.new().restore(JSON.parse_string(JSON.stringify(packet)))
		check(not restored.is_empty(),"upgraded native world remains a valid save")
		if not restored.is_empty():
			game._apply_restored(restored);await frames(4)
			key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(5)
			check(not game.paused and not growth.visible and growth.current_level()==0,"resuming a loaded camp does not replay its ceremony")
		game.restart();await frames(4)
		check(not growth.visible and growth.current_level()==0,"new journey clears old celebration state")
	game.queue_free();await process_frame
	print("Settlement growth scene assertions: %d; failures: %d"%[assertions,failures])
	quit(0 if failures==0 else 1)
