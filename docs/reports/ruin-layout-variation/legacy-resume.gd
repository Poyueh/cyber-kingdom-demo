extends SceneTree
func _initialize() -> void:
	var before: Array=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v30-ruin-before.json"))
	var after: Array=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v30-ruin-after.json"))
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var count: int=0
	for index: int in range(before.size()):
		var restored: Dictionary=codec.restore(before[index])
		assert(not restored.is_empty())
		assert(not restored.config.has("ruin_layout_version"))
		for tick: int in range(60):restored.session.advance(1.0/30,restored.body.x)
		var same: bool=load("res://application/campaign_checkpoint_rules.gd").same(codec.capture(restored.session,restored.config,restored.body),codec._normalize(after[index]))
		assert(same,"Legacy partial ruin continuation changed")
		if same:count+=1
	print("Actual v0.0.30 partial puzzles retained and sixty-tick continuations equivalent: ",count,"/6")
	quit(0 if count==6 else 1)
