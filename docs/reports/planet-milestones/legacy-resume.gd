extends SceneTree
func _initialize() -> void:
	var before: Array=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v32-voyage-before.json"))
	var after: Array=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v32-voyage-resumed.json"))
	var voyage: Script=load("res://application/star_voyage.gd")
	var report: Script=load("res://application/voyage_progress.gd")
	var count: int=0
	for index: int in range(before.size()):
		var restored: Dictionary=voyage.restore(before[index])
		assert(not restored.is_empty())
		var forest: Dictionary=report.read(restored.journey,restored.session,0)
		assert(forest.known and forest.goals.all(func(goal: Dictionary)->bool:return goal.complete))
		if index==1:
			assert(forest.core and report.read(restored.journey,restored.session,1).settlement==0)
		assert(report.read(restored.journey,restored.session,6)=={"known":false})
		for tick: int in range(60):restored.session.advance(1.0/30,restored.body.x)
		var same: bool=load("res://application/campaign_checkpoint_rules.gd").same(restored.journey.capture(restored.session,restored.body),load("res://application/campaign_snapshot.gd").new()._normalize(after[index]))
		if not same:
			FileAccess.open("/tmp/cyber-v33-legacy-actual.json",FileAccess.WRITE).store_string(JSON.stringify(restored.journey.capture(restored.session,restored.body)))
			FileAccess.open("/tmp/cyber-v33-legacy-expected.json",FileAccess.WRITE).store_string(JSON.stringify(after[index]))
			printerr("Legacy continuation differs in fixture ",index);quit(1);return
		if same:count+=1
	print("Actual v0.0.32 current and archived merits plus sixty-tick continuation: ",count,"/2")
	quit(0 if count==2 else 1)
