extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Assault=preload("res://application/biome_dragon_assault.gd")
func scene(id: int) -> RefCounted:
 var tuning: Resource=load("res://data/campaign.tres")
 var config: Dictionary=tuning.campaign_rules()
 config.merge({"seed":7120,"economy":tuning.economy_rules(),"planet_id":id,"voyage_enabled":1},true)
 return Campaign.new(config)
func test_sand_rupture_respects_finished_wall(t: SceneTree) -> void:
 var sim: RefCounted=scene(1)
 sim.world.wall.merge({"level":1,"hp":40,"pending":false},true)
 sim.pouch.amount=10
 var dragon: Dictionary=sim._spawn_raider()
 dragon.kind="dragon";dragon.x=sim.world.sites.wall+140;dragon.wall_damage=12
 dragon.target={"kind":"hero","x":sim.world.sites.wall-30}
 Assault.impact(sim,dragon,dragon.target.x,430)
 t.equal(sim.world.wall.hp,28,"sand rupture damages intervening wall")
 t.equal(sim.pouch.amount,10,"wall protects knight from ground rupture")
func test_ice_breath_aims_twice_then_recovers(t: SceneTree) -> void:
 var sim: RefCounted=scene(2)
 sim.world.people.clear()
 var dragon: Dictionary=sim._spawn_raider()
 dragon.kind="dragon";dragon.x=2000.0;dragon.direction=1.0;dragon.wall_damage=12
 dragon.windup=0.05;dragon.cooldown=8.0;dragon.target={"kind":"hero","x":2200.0}
 Assault.advance(sim,dragon,0.1,2700,430)
 t.equal(sim.planet.volley,1,"first breath schedules second strike")
 t.truth(dragon.windup>1.5,"second strike gives a fresh dodge warning")
 t.equal(dragon.target.x,2390.0,"second warning is offset from locked first aim, not retargeted onto knight")
 Assault.advance(sim,dragon,1.8,2700,430)
 t.equal(sim.effects.filter(func(e: Dictionary)->bool:return e.kind=="planet_strike").size(),2,"two impacts occur, not an endless volley")
 t.equal(dragon.windup,0.0,"dragon enters recovery after second impact")
 t.truth(dragon.cooldown>5,"player has a counterattack window")
