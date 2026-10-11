extends SceneTree
func _initialize() -> void:
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v27-settlement.json"))
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var restored: Dictionary=codec.restore(raw)
	if restored.is_empty():printerr("FAIL previous release could not resume");quit(1);return
	var sim: RefCounted=restored.session
	var before: String=JSON.stringify(codec.capture(sim,restored.config,restored.body))
	var data: Dictionary=load("res://application/settlement_progress.gd").read(sim)
	var passed: bool=data.level==2 and data.stages[1].complete and not data.stages[2].complete
	passed=passed and sim.world.tools.hoe==1 and sim.context(sim.world.sites.hall).paid==2
	passed=passed and before==JSON.stringify(codec.capture(sim,restored.config,restored.body))
	print("PASS previous v0.0.27 pack save retains tools, partial investment and stage while reviewing" if passed else "FAIL previous release changed")
	quit(0 if passed else 1)
