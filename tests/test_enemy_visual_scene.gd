extends "res://tests/test_scene.gd"
const Cast = preload("res://data/enemy_cast.tres")
const Codec = preload("res://application/campaign_snapshot.gd")
const Campaign = preload("res://application/campaign_session.gd")
const BODY: Dictionary={"x":2500.0,"y":430.0,"vx":0.0,"vy":0.0}
func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game);await frames(8);game.set_physics_process(false)
	check(Cast.valid(),"all shipped animation clips address complete native atlases")
	var codec: RefCounted=Codec.new()
	for planet: int in range(7):
		var config: Dictionary=game.journey.configs[planet].duplicate(true)
		var sim: RefCounted=Campaign.new(config);sim.world.people.clear()
		var enemy: Dictionary=sim._spawn_raider();enemy.x=2550.0;enemy.direction=-1.0
		var boss: Dictionary=sim._spawn_raider();boss.kind="dragon";boss.x=2700.0;boss.direction=-1.0
		boss.target={"kind":"hero","x":2500.0};boss.windup=1.6
		sim.raiders.assign([enemy,boss]);game.sim=sim
		game.view.present(sim,2500.0)
		check(game.view._raider_motion.appearance("warden").valid() and game.view._raider_motion.appearance("dragon").valid(),"current planet loads its complete guardian and dragon atlases")
		var before: Dictionary=codec.capture(sim,config,BODY)
		for count: int in range(4):game.view.present(sim,2500.0)
		check(preload("res://application/campaign_checkpoint_rules.gd").same(before,codec.capture(sim,config,BODY)),"presentation cannot write combat or save state on planet "+str(planet))
		check(not game.view.hit_feedback.enemy_pose(enemy).active,"loading an enemy never invents a hit")
		enemy.fighter.take_damage(18);sim.workforce.elapsed+=0.03;game.view.present(sim,2500.0)
		check(game.view.hit_feedback.enemy_pose(enemy).active,"confirmed damage plays the authored hurt clip")
		var hold: int=game.view._raider_motion.frame_for(enemy,Cast.grunt,game.view.hit_feedback.enemy_pose(enemy))
		game.view.present(sim,2500.0)
		check(hold==game.view._raider_motion.frame_for(enemy,Cast.grunt,game.view.hit_feedback.enemy_pose(enemy)),"paused damage frame remains still")
		enemy.escaped=true;enemy.fighter.hp=0;game.view.present(sim,2500.0)
		check(game.view.hit_feedback.fallen.is_empty(),"a crystal thief reaching its exit is never shown dying")
		boss.fighter.hp=0;game.view.present(sim,2500.0)
		check(game.view.hit_feedback.fallen.size()==1,"dragon death retains its whole-body collapse")
		game.view.hit_feedback.advance_terminal(1.3)
		check(game.view.hit_feedback.fallen.is_empty(),"terminal debris is removed after its lifetime")
		await frames(2)
	var empty_effects: Array[Dictionary]=[]
	game.sword_feedback.reset(empty_effects)
	var hit: Array[Dictionary]=[{"kind":"planet_strike","x":2500.0,"life":0.85}]
	game.sword_feedback.observe(hit,Vector2(2500,430))
	check(game.knight.get_node("Camera2D").offset.length()>0,"nearby confirmed dragon impact gives a short weight cue")
	var free_seconds: float=game.sword_feedback.advance(0.30)
	check(is_equal_approx(free_seconds,0.30) and game.knight.get_node("Camera2D").offset==Vector2.ZERO,"dragon weight cue neither stops gameplay nor leaves a camera offset")
	game.sword_feedback.reset(hit);game.sword_feedback.observe(hit,Vector2(2500,430))
	check(game.knight.get_node("Camera2D").offset==Vector2.ZERO,"loading with a retained impact never replays a quake")
	game.sword_feedback.reset(empty_effects);game.sword_feedback.observe(hit,Vector2(0,430))
	check(game.knight.get_node("Camera2D").offset==Vector2.ZERO,"offscreen dragon impacts do not shake the player's view")
	game.queue_free();await frames(2)
	print("Enemy visual scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
