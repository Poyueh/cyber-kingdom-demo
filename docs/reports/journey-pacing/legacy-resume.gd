extends SceneTree
func _initialize() -> void:
	var packet: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("/tmp/cyber-v28-legacy-voyage.json"))
	var Voyage: Script=load("res://application/star_voyage.gd")
	var Rules: Script=load("res://application/campaign_checkpoint_rules.gd")
	var restored: Dictionary=Voyage.restore(packet)
	if restored.is_empty():printerr("FAIL legacy voyage rejected");quit(1);return
	var actual: Dictionary=restored.journey.capture(restored.session,restored.body)
	var passed: bool=Rules.same(actual,packet)
	passed=passed and restored.journey.current==1 and restored.journey.planets[0].planet.core_claimed
	passed=passed and restored.journey.planets[0].campaign.nodes[0].collected
	passed=passed and restored.journey.configs.all(func(config: Dictionary)->bool:return not config.has("journey_style"))
	restored.session.advance(0.1,-730)
	passed=passed and not Voyage.restore(restored.journey.capture(restored.session,restored.body)).is_empty()
	print("PASS actual v0.0.28 voyage retains all rules, previous colony and can continue without a forced pace" if passed else "FAIL actual legacy voyage changed")
	quit(0 if passed else 1)
