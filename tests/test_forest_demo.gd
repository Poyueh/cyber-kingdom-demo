extends "res://tests/test_core_loop.gd"
## The public Demo plays the whole forest with the main guidance, but cannot travel:
## the forest dragon is its finale. Shared pacing changes are pinned here as well.
const Setup=preload("res://application/journey_setup.gd")
const Ops=preload("res://application/planet_operations.gd")
const Distribution=preload("res://infrastructure/distribution.gd")
const Levels=preload("res://domain/planet_level_layout.gd")
## forest_only mirrors the Demo package, whose catalogs keep only the forest entry.
func configuration(forest_only: bool=false) -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var base: Dictionary=tuning.campaign_rules()
 base.merge({"seed":1054,"economy":tuning.economy_rules()},true)
 base.level_design=load("res://data/planet_levels.tres").rules()
 base.trail_design=load("res://data/trail_encounters.tres").rules()
 base.ruin_variation=load("res://data/ruin_variation.tres").rules()
 if forest_only:
  base.level_design.profiles=base.level_design.profiles.slice(0,1)
  base.trail_design=base.trail_design.slice(0,1)
 var forest: Resource=load("res://data/planets/forest.tres")
 var config: Dictionary=Setup.create_forest(base,forest.rules(),load("res://data/journey_paces.tres").find(0).rules())
 config.merge(Setup.gate_rules(forest),true)
 var profile: Resource=load("res://data/core_loop.tres")
 return profile.resolve_demo(config) if profile.has_method("resolve_demo") else config
func _initialize() -> void:
 var config: Dictionary=configuration()
 check(config.get("core_loop_version",0)==3 and config.get("voyage_enabled",-1)==0,"demo journeys use the contained forest mode")
 check(Rules.config_valid(config),"contained forest configuration passes save validation")
 var wrong: Dictionary=config.duplicate(true);wrong.voyage_enabled=1
 check(not Rules.config_valid(wrong),"contained forest cannot claim star travel")
 var main_like: Dictionary=config.duplicate(true);main_like.core_loop_version=2
 check(not Rules.config_valid(main_like),"main guidance still requires star travel")
 var sim: RefCounted=Campaign.new(config)
 check(sim.core_loop.enabled and not sim.core_loop.trial,"demo keeps the main outcome-driven guidance")
 check(sim.core_loop.get("contained")==true,"demo run knows it is the contained forest")
 check(sim.frontier.right_boundary>5000,"demo plays the full forest map, not the small trial camp")
 check(sim.merchant.enabled,"demo includes the crystal merchant")
 check(sim.modules.relics.size()>0,"demo includes ruin puzzles and their modules")
 check(sim.mount_quest.enabled,"demo includes the forest warhorse expedition")
 check(sim.mission.rifts.size()==int(config.rift_left_count)+int(config.rift_right_count),"demo has the forest gates for engineers to seal")
 check(not sim.planet.enabled,"demo has no rocket or star travel")
 pacing()
 packaged_catalogs()
 if not sim.core_loop.enabled or sim.core_loop.trial:
  print("Forest demo: %d assertions, %d failures"%[assertions,failures]);quit(1);return
 run_flow()
 print("Forest demo: %d assertions, %d failures"%[assertions,failures]);quit(1 if failures else 0)

func verify_completion(sim: RefCounted, config: Dictionary, codec: RefCounted) -> void:
 check(sim.is_running() and not sim.finished(),"demo continues in the same forest after the two guided nights")
 var body: Dictionary={"x":0.0,"y":430.0,"vx":0.0,"vy":0.0}
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(codec.capture(sim,config,body))))
 check(not restored.is_empty() and restored.session.core_loop.contained,"demo forest saves as a single contained world")
 if not restored.is_empty():
  ProjectSettings.set_setting("distribution/edition","demo")
  check(Distribution.accepts(restored),"demo edition loads contained forest records")
  check(not Distribution.accepts(restored.merged({"journey":RefCounted.new()})),"demo edition still refuses seven-world records")
  ProjectSettings.set_setting("distribution/edition","full")
 for rift: Dictionary in sim.mission.rifts:rift.sealed=true
 sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
 sim.raiders.clear()
 sim.advance(0.1,30)
 check(sim.mission.outcome=="victory" and sim.finished(),"defeating the forest dragon completes the demo")
 check(Ops.candidates(sim,Ops.rocket_x(sim),430.0).is_empty(),"demo offers no rocket after the dragon")

## The Demo package strips the other six worlds from the route and roadside catalogs.
func packaged_catalogs() -> void:
 var routes: Dictionary=load("res://data/planet_levels.tres").rules()
 check(Levels.valid_options({"version":1,"profiles":routes.profiles.slice(0,1)}),"a forest-only route catalog is a valid package")
 check(not Levels.valid_options({"version":1,"profiles":[]}),"an empty route catalog is refused")
 check(not Levels.valid_options({"version":1,"profiles":routes.profiles.slice(1,2)}),"a route catalog must start with the forest")
 check(configuration(true)==configuration(),"the Demo package builds exactly the journey's forest")

## Shared with the main game: the warning runs while the ordered archer walks,
## but night never falls before that archer reaches the wall.
func pacing() -> void:
 var sim: RefCounted=Campaign.new(configuration())
 check(sim.interact(sim.world.sites.hall,"hall"),"camp lights")
 for i: int in range(240):sim.advance(1.0/30.0,sim.world.sites.hall)
 sim.core_loop.income=4;sim.core_loop.stage=1;sim.core_loop.checkpoint_index=1;sim.core_loop.checkpoint_pending=0
 sim.world.walls.wall.merge({"level":1,"hp":40,"pending":false},true)
 var archer: int=-1
 for i: int in range(sim.world.people.size()):
  if sim.world.people[i].role=="wanderer":archer=i;break
 check(archer>=0,"a resident can become the archer")
 if archer<0:return
 sim.world.people[archer].role="hunter"
 sim.world.people[archer].x=sim.world.sites.hall-2600.0
 sim.investments.clear()
 check(sim.core_loop.orders.assign(sim,"wall",1),"archer accepts the right-wall order")
 sim.advance(1.0/30.0,sim.world.sites.hall)
 check(sim.core_loop.stage==2,"first-night warning starts when the archer is ordered, not when they arrive")
 var held: bool=false
 for i: int in range(30*240):
  sim.advance(1.0/30.0,sim.world.sites.hall)
  var arrived: bool=sim.core_loop.orders.arrived(sim,"wall",sim.core_loop.arrival_radius)>=sim.core_loop.minimum_defenders
  if sim.clock.is_night:
   check(arrived,"night falls only after the ordered archer reaches the wall")
   break
  if not arrived and sim.clock.remaining<=sim.core_loop.ARRIVAL_HOLD_SECONDS+0.01:held=true
 check(held,"a long walk holds dusk instead of starting the night undefended")
 check(sim.clock.is_night,"first night still arrives once the archer is in place")
