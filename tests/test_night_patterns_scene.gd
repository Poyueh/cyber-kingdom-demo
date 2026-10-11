extends "res://tests/test_scene.gd"
const AudioCues = preload("res://presentation/campaign_audio_cues.gd")
func shot(game: Node, name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/night-patterns")
	game.get_viewport().get_texture().get_image().save_png("res://test-results/night-patterns/"+name+".png")

func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game);await frames(10)
	game.sim.frontier.city_level=1;game.sim.survival.armed=true
	game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
	game.sim.clock.day=4;game.sim.clock.survived=3;game.sim.clock.remaining=80
	var cues: RefCounted=AudioCues.new()
	cues.sample(game.sim,30,false)
	game.sim.clock.remaining=74.9
	check(cues.sample(game.sim,30,false).has("raid_warning"),"native warning sound is scheduled early enough to return")
	check(not cues.sample(game.sim,30,false).has("raid_warning"),"sound observer does not repeat its warning each frame")
	await frames(35)
	check(game.hud.night_watch_view.visible,"real HUD shows tactical warning near dusk")
	for locale: String in ["zh_TW","zh_CN","en"]:
		TranslationServer.set_locale(locale);game.hud.control_mode=1 if locale=="en" else 2
		await frames(5)
		check(not game.hud.night_watch_view.caption.text.begins_with("night."),"tactical description is translated: "+locale)
		check(game.hud.night_watch_view.caption.size.x>100,"warning has room inside the safe area")
		await shot(game,locale)
	key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
	check(not game.hud.night_watch_view.visible,"pause hides the transient warning")
	var remaining: float=game.sim.clock.remaining
	await frames(10)
	check(is_equal_approx(game.sim.clock.remaining,remaining),"opening options cannot consume preparation time")
	key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
	game.sim.clock.day=5;game.sim.clock.survived=4;game.sim.clock.remaining=0.01
	await frames(8)
	check(game.sim.clock.is_night and game.sim.raiders.front().side==-1,"real scene starts the western wave")
	await shot(game,"pincer")
	game.queue_free();await process_frame
	print("Night pattern scene assertions: %d; failures: %d"%[assertions,failures])
	quit(0 if failures==0 else 1)
