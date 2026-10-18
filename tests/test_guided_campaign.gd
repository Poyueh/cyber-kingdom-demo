extends "res://tests/test_core_loop.gd"
var journey: RefCounted
func configuration() -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var base: Dictionary=tuning.campaign_rules()
 base.merge({"seed":1054,"economy":tuning.economy_rules()},true)
 base.level_design=load("res://data/planet_levels.tres").rules()
 base.trail_design=load("res://data/trail_encounters.tres").rules()
 base.ruin_variation=load("res://data/ruin_variation.tres").rules()
 var profiles: Array[Dictionary]=[]
 for name: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:profiles.append(load("res://data/planets/"+name+".tres").rules())
 journey=load("res://application/journey_setup.gd").create(base,profiles,load("res://data/journey_paces.tres").find(0).rules())
 var profile: Resource=load("res://data/core_loop.tres")
 if profile.has_method("resolve_campaign"):
  for i: int in range(7):journey.configs[i]=profile.resolve_campaign(journey.configs[i])
 return journey.configs[0]
func _initialize() -> void:
 var config: Dictionary=configuration()
 var sim: RefCounted=Campaign.new(config)
 check(sim.core_loop.enabled,"new main journey includes the same outcome-driven guidance")
 check(sim.planet.enabled and sim.frontier.right_boundary>5000,"guided forest retains its full world and travel capability")
 check(sim.modules.relics.size()>0 and sim.merchant.enabled,"main journey retains its discoveries and merchant")
 check(Rules.config_valid(config),"guided main configuration passes save validation")
 if not sim.core_loop.enabled:
  print("Guided campaign: %d assertions, %d failures"%[assertions,failures]);quit(1);return
 run_flow()
 print("Guided campaign: %d assertions, %d failures"%[assertions,failures]);quit(1 if failures else 0)
func verify_completion(sim: RefCounted, _config: Dictionary, _codec: RefCounted) -> void:
 check(sim.is_running() and not sim.finished(),"main journey continues in the same settlement after two nights")
 check(sim.site_visible("trade")==false and sim.site_visible("hall"),"normal main-game building rules resume after guidance")
 var body: Dictionary={"x":0.0,"y":430.0,"vx":0.0,"vy":0.0}
 var saved: Dictionary=journey.capture(sim,body)
 var resumed: Dictionary=load("res://application/star_voyage.gd").restore(JSON.parse_string(JSON.stringify(saved)))
 check(not resumed.is_empty(),"guided forest saves and resumes inside seven-world envelope")
 if not resumed.is_empty():check(resumed.session.is_running(),"loaded completed guidance does not end the main game")
 check(sim.core_loop.checkpoint.is_empty(),"completed main guidance retires preparation retry")
 var other: RefCounted=Campaign.new(journey.configs[1])
 check(other.core_loop.enabled and other.core_loop.stage==5,"other planets retain shared improvements without repeating forest lessons")
 check(not _codec.restore(_codec.capture(other,journey.configs[1],body)).is_empty(),"new later planet saves before any local income")
 check(other.hero.stats.attack_cost==0,"main-game other planets share free ordinary attacks")
 var choices: Array[Dictionary]=[{"id":"module"}]
 check(other.core_loop.filter_choices(other,choices).size()==1,"main-game later interactions are not restricted to trial actions")
 test_travel(sim)


func test_travel(sim: RefCounted) -> void:
 load("res://tests/test_star_voyage.gd").new().cleared(sim)
 sim.planet.claim_core();sim.planet.rocket_ready=true
 var trip: Dictionary=journey.prepare(sim,{"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0},1)
 check(not trip.is_empty(),"completed guided settlement can take the real voyage transaction")
 if not trip.is_empty():
  check(trip.session.core_loop.stage==5 and trip.session.hero.stats.attack_cost==0,"arrival keeps common controls without restarting lessons")
