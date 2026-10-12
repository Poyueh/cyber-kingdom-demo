extends "res://tests/test_scene.gd"
func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	root.add_child(game);await frames(4)
	game.knight.position=Vector2(game.sim.world.sites.hall,430);await frames(3)
	key(KEY_E,true);await frames(2);key(KEY_E,false)
	await frames(30)
	var start: float=game.knight.position.x
	key(KEY_D,true);key(KEY_J,true);await frames(5);key(KEY_J,false)
	check(is_equal_approx(game.knight.position.x,start),"drawing the first sword completes before held movement resumes")
	check(game.sim.hero.attack_remaining==0,"attack cannot replace an unfinished sword extraction")
	check(game.knight.visual._ceremony.visible,"extraction stays visible through queued movement and attack")
	key(KEY_D,false)
	check(game.view.camp_reveal.progress()==0,"all founding buildings remain hidden during extraction")
	game.paused=true
	var held: float=game.knight.visual.ceremony_age
	await frames(8)
	check(game.knight.visual.ceremony_age==held and game.view.camp_reveal.progress()==0,"pause freezes extraction and building reveal together")
	game.paused=false
	for unused: int in range(200):
		await frames(1)
		if game.view.camp_reveal.progress()>0:break
	check(not game.knight.visual._ceremony.visible,"construction begins only after the extraction body has finished")
	check(game.view.camp_reveal.progress()>0 and game.view.camp_reveal.progress()<1,"camp starts a gradual grounded assembly after extraction")
	await frames(65)
	check(game.view.camp_reveal.progress()==1,"camp assembly completes and exposes buildings and attendants")
	key(KEY_D,true);await frames(5);key(KEY_D,false)
	check(game.knight.position.x>start,"movement resumes normally after extraction")
	game.restart();await frames(3)
	check(game.view.camp_reveal.progress()==1 and not game.knight.visual._ceremony.visible,"restart discards the previous founding transition")
	game.queue_free();await process_frame
	print("Founding scene assertions: %d; failures: %d"%[assertions,failures])
	quit(0 if failures==0 else 1)
