extends SceneTree
func _initialize() -> void:
	var reports: Array[Dictionary]=[]
	for biome: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:
		for seed_value: int in [103,742601,8842]:
			var tuning: Resource=load("res://data/campaign.tres")
			var config: Dictionary=tuning.campaign_rules()
			config.merge({"seed":seed_value,"economy":tuning.economy_rules()},true)
			config.merge(load("res://data/planets/%s.tres"%biome).rules(),true)
			var sim: RefCounted=load("res://application/campaign_session.gd").new(config)
			sim.frontier.city_level=1;sim.survival.armed=true;sim.world.people.clear()
			for id: String in ["wall","wall_left"]:
				sim.world.walls[id].level=1;sim.world.walls[id].hp=40
			sim.clock.remaining=0.01;sim.clock.day=4;sim.clock.survived=3
			var first_contact: float=-1;var dawn: float=-1;var resolved: int=0
			for tick: int in range(3600):
				sim.advance(0.1,30.0)
				for enemy: Dictionary in sim.raiders:
					var wall_x: float=sim.world.sites.wall_left if enemy.side<0 else sim.world.sites.wall
					if (enemy.x-wall_x)*enemy.side<=320 and enemy.fighter.is_alive():
						if first_contact<0:first_contact=(tick+1)*0.1
						enemy.fighter.hp=0;resolved+=1
				if sim.clock.day==5:dawn=(tick+1)*0.1;break
			reports.append({"biome":biome,"seed":seed_value,"gate_west":sim.mission.entry_x(-1),"gate_east":sim.mission.entry_x(1),"first_defense_contact_seconds":first_contact,"night_seconds_if_instantly_defeated_at_320_range":dawn,"resolved":resolved})
	print(JSON.stringify(reports))
	quit()
