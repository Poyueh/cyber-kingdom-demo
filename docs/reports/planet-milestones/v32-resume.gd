extends SceneTree
func _initialize() -> void:
	var before: Array=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v32-voyage-before.json"))
	var results: Array[Dictionary]=[]
	for packet: Dictionary in before:
		var restored: Dictionary=load("res://application/star_voyage.gd").restore(packet)
		assert(not restored.is_empty())
		for tick: int in range(60):restored.session.advance(1.0/30,restored.body.x)
		results.append(restored.journey.capture(restored.session,restored.body))
	FileAccess.open("/tmp/cyber-v32-voyage-resumed.json",FileAccess.WRITE).store_string(JSON.stringify(results))
	print("Actual v0.0.32 PCK: two saved journeys reloaded and continued for sixty ticks.")
	quit()
