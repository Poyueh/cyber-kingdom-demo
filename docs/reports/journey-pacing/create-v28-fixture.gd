extends SceneTree
func _initialize() -> void:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.merge({"seed":10628,"economy":tuning.economy_rules()},true)
	var profiles: Array[Dictionary]=[]
	for name: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:
		profiles.append(load("res://data/planets/"+name+".tres").rules())
	var journey: RefCounted=load("res://application/star_voyage.gd").new(config,profiles)
	var sim: RefCounted=load("res://application/campaign_session.gd").new(journey.configs[0])
	for rift: Dictionary in sim.mission.rifts:rift.sealed=true
	sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
	sim.frontier.city_level=1;sim.survival.armed=true
	sim.frontier.nodes[0].collected=true;sim.frontier.nodes[0].delivered=true
	sim.advance(0.1,30);sim.planet.claim_core();sim.planet.rocket_ready=true
	var body: Dictionary={"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}
	var trip: Dictionary=journey.prepare(sim,body,1)
	if trip.is_empty():printerr("FAIL legacy voyage could not travel");quit(1);return
	var packet: Dictionary=trip.journey.capture(trip.session,trip.body)
	var file: FileAccess=FileAccess.open("/tmp/cyber-v28-legacy-voyage.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(packet));file.close()
	print("Previous release voyage current planet: ",packet.current," schema: ",packet.planets[1].campaign.version," pace marked: ",packet.configs[0].has("journey_style"))
	quit()
