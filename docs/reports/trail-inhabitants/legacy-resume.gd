extends SceneTree
func _initialize() -> void:
	var before: Array=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v36-level-before.json"))
	var after: Array=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v36-level-after.json"))
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var count: int=0
	for index: int in range(before.size()):
		var restored: Dictionary=codec.restore(before[index])
		assert(not restored.is_empty())
		assert(restored.config.has("level_design_version"))
		assert(not restored.config.has("trail_version"))
		assert(restored.session.frontier.regions.size()==14)
		for tick: int in range(60):restored.session.advance(1.0/30,restored.body.x)
		after[index].version=20;after[index]["trails"]={"sites":[],"units":[]}
		var same: bool=load("res://application/campaign_checkpoint_rules.gd").same(codec.capture(restored.session,restored.config,restored.body),codec._normalize(after[index]))
		assert(same,"Legacy world continuation changed")
		if same:count+=1
	print("Actual v0.0.36 maps, puzzles, resources and sixty-tick continuation: ",count,"/7 preserved")
	quit(0 if count==7 else 1)
