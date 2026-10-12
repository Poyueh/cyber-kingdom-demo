extends "res://tests/test_scene.gd"
## Real campaign composition, exercising its public strike path against silhouettes.
var game: Node
func run_scene() -> void:
	game=load("res://scenes/frontier.tscn").instantiate()
	root.add_child(game);await frames(4);game.set_physics_process(false)
	game.sim.interact(game.sim.world.sites.hall)
	for facing: int in [-1,1]:
		for sample: Array in [["raider",90.0],["warden",112.0],["dragon",205.0]]:
			var enemy: Dictionary=target(sample[0],facing*float(sample[1]),-facing)
			swing(facing)
			check(enemy.fighter.hp==482,"visible %s body contact connects facing %d"%[sample[0],facing])
			var after_hit: int=enemy.fighter.hp
			game.sim.strike_from(0,430)
			check(enemy.fighter.hp==after_hit,"one cut cannot damage %s twice"%sample[0])
	var behind: Dictionary=target("raider",-12,1)
	swing(1);check(behind.fighter.hp==500,"body radius cannot turn a forward cut into a rear hit")
	var distant: Dictionary=target("raider",150,-1)
	swing(1);check(distant.fighter.hp==500,"clear space beyond blade and body remains a miss")
	for sample: Array in [["raider",102.0,true],["raider",106.0,false],["warden",125.0,true],["warden",130.0,false],["dragon",230.0,true],["dragon",234.0,false]]:
		var boundary: Dictionary=target(sample[0],sample[1],-1)
		swing(1);check((boundary.fighter.hp<500)==sample[2],"%s silhouette boundary at %d"%[sample[0],sample[1]])
	var rear_edge: Dictionary=target("raider",96,1)
	swing(1);check(rear_edge.fighter.hp==500,"turning away uses the shorter rear silhouette")
	var light: Dictionary=target("raider",109,-1)
	swing(1);check(light.fighter.hp==500,"light blade does not borrow the heavy cleave extension")
	var heavy: Dictionary=target("raider",109,-1)
	swing(1,3);check(heavy.fighter.hp==471,"heavy blade's visible extension deals the existing 29 damage")
	# Preserve authored roaming creatures so the snapshot is a valid whole world.
	game.restart();game.sim.interact(game.sim.world.sites.hall)
	var saved_enemy: Dictionary=game.sim._spawn_raider()
	saved_enemy.x=90.0;saved_enemy.direction=-1.0
	game.sim.raiders.append(saved_enemy)
	swing(1)
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var saved: Dictionary=codec.capture(game.sim,game._campaign_config,{"x":0.0,"y":430.0,"vx":0.0,"vy":0.0})
	var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
	check(not restored.is_empty(),"contact geometry does not change the v20 save shape")
	if not restored.is_empty():
		game._apply_restored(restored)
		game.sim.raiders.back().fighter.invulnerability_remaining=0
		game.sim.strike_from(0,430)
		check(game.sim.raiders.back().fighter.hp==42,"restoring mid-cut never duplicates a hit")
		check(game.sim.sword_contact.configured,"restored campaigns receive the corrected contact profile")
	var old_path: String="res://tests/fixtures/campaign-v20-v40-contact.json"
	if FileAccess.file_exists(old_path):
		var old: Dictionary=codec.restore(JSON.parse_string(FileAccess.get_file_as_string(old_path)))
		check(not old.is_empty(),"actual v0.0.40 package save opens without migration")
		if not old.is_empty():
			game._apply_restored(old)
			var old_target: Dictionary=target("raider",90,-1)
			swing(1);check(old_target.fighter.hp==482,"existing journeys also receive body-edge contact correction")
	game.queue_free();await process_frame
	print("Sword contact scene assertions: %d; failures: %d"%[assertions,failures])
	quit(0 if failures==0 else 1)
func target(kind: String, x: float, direction: float) -> Dictionary:
	game.sim.raiders.clear()
	game.sim.hero.advance(2.0)
	var enemy: Dictionary=game.sim._spawn_raider()
	enemy.kind=kind;enemy.x=x;enemy.direction=direction;enemy.fighter.hp=500;enemy.fighter.stats.max_hp=500;enemy.fighter.stats.hurt_invulnerability=0.0
	game.sim.raiders.append(enemy)
	return enemy
func swing(facing: int, step: int=1) -> void:
	game.sim.hero.facing=facing;game.sim.hero.stamina=100
	game.sim.hero.start_attack()
	for unused: int in range(1,step):
		game.sim.hero.advance(game.sim.hero.attack_remaining);game.sim.hero.start_attack()
	game.sim.hero.advance(game.sim.hero.attack_remaining*0.5)
	game.sim.strike_from(0,430)
