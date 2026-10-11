extends SceneTree
func _initialize() -> void:
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v26-night-checkpoint.json"))
	assert(raw.version==18)
	var restored: Dictionary=codec.restore(raw)
	assert(not restored.is_empty(),codec.last_error)
	var sim: RefCounted=restored.session
	assert(not sim.night_pattern.enabled)
	var before: int=sim._night_spawn_index
	for enemy: Dictionary in sim.raiders:enemy.fighter.hp=0
	var new_sides: Array[int]=[]
	for tick: int in range(160):
		sim.advance(0.1,30.0)
		for enemy: Dictionary in sim.raiders:
			if enemy.fighter.is_alive():new_sides.append(enemy.side);enemy.fighter.hp=0
	assert(new_sides==[1,-1,1,-1,1],str(new_sides))
	var saved: Dictionary=codec.capture(sim,restored.config,restored.body)
	assert(saved.version==19)
	assert(not codec.restore(JSON.parse_string(JSON.stringify(saved))).is_empty())
	print("PASS: actual v0.0.26 checkpoint resumed after ",before," spawns; remaining arrivals alternate; resaves as v19.")
	quit()
