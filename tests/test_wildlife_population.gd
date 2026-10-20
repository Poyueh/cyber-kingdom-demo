extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Snapshot=preload("res://application/campaign_snapshot.gd")
const Fixture=preload("res://tests/test_resident_revert.gd")
func config(expanded: bool=true) -> Dictionary:
 var old: RefCounted=Fixture.new().guided()
 var rules: Dictionary=load("res://data/campaign.tres").campaign_rules()
 rules.merge({"seed":old.map_seed,"economy":load("res://data/campaign.tres").economy_rules()},true)
 var profile: Resource=load("res://data/planets/forest.tres")
 var setup: Script=load("res://application/journey_setup.gd")
 rules=setup.create_forest(rules,profile.rules(),load("res://data/journey_paces.tres").find(0).rules())
 rules.merge(setup.gate_rules(profile),true)
 rules=load("res://data/core_loop.tres").resolve_demo(rules)
 for key: String in rules.keys():
  if key.begins_with("wildlife_"):rules.erase(key)
 if expanded:rules.merge(load("res://data/wildlife_population.tres").rules(),true)
 return rules
func test_new_forest_has_game_on_both_sides_and_in_distant_woodlands(t):
 var rules: Dictionary=config()
 var sim: RefCounted=Campaign.new(rules)
 var near_left: int=0
 var near_right: int=0
 var far: int=0
 for animal: Dictionary in sim.frontier.animals:
  if animal.x<sim.world.sites.wall_left and animal.x> -1500:near_left+=1
  elif animal.x>sim.world.sites.wall and animal.x<1500:near_right+=1
  elif absf(animal.x)>1500:far+=1
  var region: Dictionary=sim.frontier.regions[animal.region]
  t.truth(animal.x>=region.x and animal.x<region.x+region.width,"prey belongs to its actual habitat")
 t.equal(near_left,3,"three spaced prey west of the walls")
 t.equal(near_right,3,"three spaced prey east of the walls")
 t.truth(far>0,"full forest also keeps game in distant woodland")
 t.truth(sim.frontier.animals.size()<=24,"forest population is bounded, not a crowd")
 var other: RefCounted=Campaign.new(rules)
 t.equal(sim.frontier.animals,other.frontier.animals,"same seed gives the same prey slots without new random draws")
func test_saved_prey_and_legacy_population_are_not_restocked(t):
 var rules: Dictionary=config()
 var sim: RefCounted=Campaign.new(rules)
 sim.frontier.animals[0].alive=false
 for i: int in range(30):sim.advance(1.0/30,30)
 var codec: RefCounted=Snapshot.new()
 var saved: Dictionary=codec.capture(sim,rules,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not restored.is_empty(),"expanded population survives JSON save/load")
 if restored.is_empty():return
 for i: int in range(30):
  sim.advance(1.0/30,30);restored.session.advance(1.0/30,30)
 var same: bool=sim.frontier.animals.size()==restored.session.frontier.animals.size()
 for index: int in range(sim.frontier.animals.size()):
  var a: Dictionary=sim.frontier.animals[index]
  var b: Dictionary=restored.session.frontier.animals[index]
  same=same and a.alive==b.alive and a.region==b.region and absf(a.x-b.x)<0.000001
 t.truth(same,"save continuation keeps live/dead status and movement within JSON precision")
 var legacy_rules: Dictionary=config(false)
 var legacy: RefCounted=Campaign.new(legacy_rules)
 t.equal(legacy.frontier.animals.size(),2,"unmarked old guided forest keeps its original two slots")
 var old_save: Dictionary=codec.capture(legacy,legacy_rules,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 var old_restored: Dictionary=codec.restore(old_save)
 t.truth(not old_restored.is_empty(),"old population still loads")
 if not old_restored.is_empty():t.equal(old_restored.session.frontier.animals.size(),2,"loading old forest does not insert animals")
func test_new_prey_slots_renew_only_at_dawn_with_a_standing_habitat(t):
 var sim: RefCounted=Campaign.new(config())
 var before: int=sim.frontier.animals.size()
 for animal: Dictionary in sim.frontier.animals:animal.alive=false
 sim.ecology.renew(2,sim.world.people)
 t.truth(sim.frontier.animals.all(func(a: Dictionary)->bool:return a.alive),"standing habitats renew the authored slots")
 sim.ecology.renew(2,sim.world.people)
 t.equal(sim.frontier.animals.size(),before,"repeated updates never add more slots")

func test_bad_population_configuration_is_refused(t):
 var rules: Dictionary=config()
 var sim: RefCounted=Campaign.new(rules)
 var codec: RefCounted=Snapshot.new()
 var saved: Dictionary=codec.capture(sim,rules,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 saved.config.wildlife_per_forest=999
 t.truth(codec.restore(saved).is_empty(),"unbounded population cannot be loaded")
 saved.config.wildlife_per_forest=3;saved.config.wildlife_near_0=0
 t.truth(codec.restore(saved).is_empty(),"corrupt camp prey placement is refused")
