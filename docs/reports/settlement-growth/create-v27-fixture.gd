extends SceneTree
func _initialize() -> void:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.merge({"seed":108,"economy":tuning.economy_rules()},true)
	var sim: RefCounted=load("res://application/campaign_session.gd").new(config)
	sim.interact(sim.world.sites.hall);sim.pouch.amount=30
	var cost: int=sim.context(sim.world.sites.hall).cost
	for i: int in range(cost):sim.interact(sim.world.sites.hall)
	cost=sim.context(sim.world.sites.farm_tools).cost
	for i: int in range(cost):sim.interact(sim.world.sites.farm_tools)
	sim.interact(sim.world.sites.hall);sim.interact(sim.world.sites.hall)
	var save: Dictionary=load("res://application/campaign_snapshot.gd").new().capture(sim,config,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
	var file: FileAccess=FileAccess.open("/tmp/cyber-v27-settlement.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(save));file.close()
	print("Previous release schema ",save.version," camp ",sim.frontier.city_level," hoes ",sim.world.tools.hoe," partial camp payment ",sim.context(sim.world.sites.hall).paid)
	quit(0 if sim.frontier.city_level==2 and sim.world.tools.hoe==1 else 1)
