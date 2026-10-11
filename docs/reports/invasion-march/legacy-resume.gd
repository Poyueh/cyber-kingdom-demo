extends SceneTree
func _initialize() -> void:
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v29-march-save.json"))
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v29-march-continued.json"))
	var loaded: Dictionary=codec.restore(saved)
	if loaded.is_empty():printerr("FAIL: previous release save rejected");quit(1);return
	for tick: int in range(60):loaded.session.advance(1.0/30.0,30.0)
	var actual: Dictionary=codec.capture(loaded.session,loaded.config,loaded.body)
	var identical: bool=load("res://application/campaign_checkpoint_rules.gd").same(expected,actual)
	print("Previous release sixty-tick continuation equivalent: ",identical)
	print("Previous release march profile still absent: ",not loaded.config.has("march_version"))
	quit(0 if identical and not loaded.config.has("march_version") else 1)
