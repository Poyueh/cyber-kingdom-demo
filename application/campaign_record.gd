extends RefCounted
## Read-only metadata through the same validated checkpoint boundary used for play.
const Progress=preload("res://application/campaign_progress.gd")
const Store=preload("res://application/ports/campaign_store.gd")
static func describe(store: Store) -> Dictionary:
	var progress=Progress.new(store)
	var restored: Dictionary=progress.open()
	if restored.is_empty():return {"status":progress.status}
	var sim=restored.session
	return {"status":"ready","day":sim.clock.day,"settlement":sim.frontier.city_level,
		"core":sim.core_loop.enabled,"pace":int(restored.config.get("journey_style",-1)),"seed":sim.map_seed,"outcome":sim.mission.outcome,"crystals":sim.pouch.amount}
