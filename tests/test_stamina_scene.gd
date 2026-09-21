extends "res://tests/test_scene.gd"
func run_scene() -> void:
	var game=load("res://scenes/frontier.tscn").instantiate();game.tuning=game.tuning.duplicate();game.tuning.immersive_loop=false;game.tuning.initial_crystals=12
	root.add_child(game);await frames(12)
	game.sim.hero.stats.stamina_regen=0
	game.sim.hero.stamina=0
	game.paused=false
	for code in [KEY_J,KEY_L,KEY_SPACE]:
		key(code,true);await frames(2);key(code,false);await frames(2)
	check(game.sim.hero.attack_remaining==0 and game.sim.hero.dash_remaining==0 and game.knight.is_on_floor(),"empty stamina blocks real attack, dash and jump input")
	game.sim.hero.stamina=50
	for code in [KEY_SPACE,KEY_L]:
		key(code,true);await frames(2);key(code,false)
	check(game.knight.is_on_floor() and game.sim.hero.stamina==50 and game.sim.hero.dash_remaining==0,"removed jump and dash cannot activate even with energy")
	key(KEY_D,true);await frames(5)
	var slow: float=game.knight.velocity.x
	check(game.sim.hero.stamina==50,"first travel tier costs no stamina")
	key(KEY_SHIFT,true);await frames(10)
	check(game.knight.velocity.x>slow and game.sim.hero.stamina<50,"Shift selects faster movement and spends real stamina")
	game.sim.hero.stamina=0;await frames(3)
	check(is_equal_approx(game.knight.velocity.x,slow),"exhaustion falls back to slow travel")
	key(KEY_D,false);key(KEY_SHIFT,false)
	check(game.hud.dashboard.values.stamina==0,"HUD reads depleted live stamina")
	game.queue_free();await process_frame
	print("Stamina scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
