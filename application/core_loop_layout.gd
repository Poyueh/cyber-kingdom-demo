extends RefCounted
const Harvest=preload("res://domain/harvest_node.gd")
const Streams=preload("res://domain/rng/rng_streams.gd")
const Trails=preload("res://domain/trail_encounters.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
const Sites=preload("res://domain/building_sites.gd")
## Camp spacing: every structure between the walls keeps at least 150 px from its neighbour
## (a tower may stand close to its wall). Hall 30; module workshop hall+180; shrine hall+330;
## the rocket pad hall-760 between the left tower and the hunting tools.
const LEFT_WALL: float=-1000.0
const LEFT_TOWER: float=-880.0
const RIGHT_TOWER: float=970.0
const RIGHT_WALL: float=1060.0
const CAMP_SITES: Dictionary={"farm_tools":-130.0,"farm":-280.0,"hunt_tools":-580.0,"workshop":670.0,"armory":820.0}
## The two trees inside the camp are authored exactly; the wild ones keep seed variation.
## Wild trees and game stay inside the discovered camp regions (west of -1300 is an unexplored room).
const CAMP_TREES: Array[float]=[-430.0,510.0]
const WILD_TREES: Array[float]=[-1270.0,-1150.0,1260.0,1450.0]
const GAME: Array[float]=[-1220.0,1380.0]
const TREE_JITTER: float=28.0
## Small authored skeleton; seed variation never removes the essential income path.
static func apply(sim: RefCounted, config: Dictionary) -> void:
 var map: RefCounted=sim.frontier
 map.left_boundary=-2800.0;map.right_boundary=2800.0
 map.regions.clear();map.nodes.clear();map.animals.clear()
 for bounds: Vector2 in [Vector2(-1500,1500),Vector2(0,1500),Vector2(-2800,1300),Vector2(1500,1300)]:
  map.regions.append({"kind":"forest","x":bounds.x,"width":bounds.y,"discovered":absf(bounds.x)<1600,"outpost_x":bounds.x+bounds.y*0.5,"outpost_ready":false,"outpost_pending":false,"outpost_built":false,"outpost_progress":0.0})
 var rng: RandomNumberGenerator=Streams.new(sim.map_seed).of(Streams.Stream.LEVEL_LAYOUT)
 for position: float in WILD_TREES+CAMP_TREES:
  var node: Harvest=Harvest.new();node.kind="tree"
  var jitter: float=rng.randf_range(-TREE_JITTER,TREE_JITTER)
  node.x=position+(0.0 if position in CAMP_TREES else jitter);node.pickup_x=node.x;node.region=0 if position<0 else 1
  node.crystals=int(config.tree_crystals);map.nodes.append(node)
 configure_trails(sim,config)
 for position: float in GAME:map.animals.append({"x":position,"region":0 if position<0 else 1,"alive":true})
 sim.world.people.clear()
 for position: float in [180.0,245.0,-1250.0,1300.0]:sim._add_person(position,-1)
 sim.world.sites.wall=RIGHT_WALL;sim.world.sites.wall_left=LEFT_WALL;sim.world.sites.beacon=LEFT_TOWER
 sim.world.sites.merge(CAMP_SITES,true)
 for id: String in sim.world.walls.keys():
  if id not in ["wall","wall_left"]:sim.world.walls.erase(id);sim.world.sites.erase(id)
 sim.world.wall=sim.world.walls.wall
 sim.defenses.plots.clear()
 sim.buildings={"beacon":Sites._site("tower",LEFT_TOWER,-1,-1),"core_tower_right":Sites._site("tower",RIGHT_TOWER,-1,-1)}
 sim.mission.rifts.clear();sim.mission.add_rift(-1,-2500.0);sim.mission.add_rift(1,2500.0)
 sim.raiders.clear()
 preload("res://application/trail_activity.gd").populate(sim)
 sim.pouch.platforms.clear();sim.pouch.left_boundary=map.left_boundary;sim.pouch.right_boundary=map.right_boundary
 sim.merchant.enabled=false
 sim.modules.relics.clear()

static func configure_trails(sim: RefCounted, config: Dictionary) -> void:
 var trails: Trails=sim.trails
 for key: String in preload("res://domain/trail_rules.gd").LIMITS:trails.rules[key]=config["core_trail_"+key]
 trails.windup_ticks=Clock.ticks_for(trails.rules.windup_seconds)
 trails.recovery_ticks=Clock.ticks_for(trails.rules.recovery_seconds)
 trails.charge_ticks=Clock.ticks_for(trails.rules.charge_seconds)
 trails.sites.clear();trails.units.clear()
 for index: int in range(2):
  var site: Trails.Site=Trails.Site.new();site.x=1950.0 if index==0 else -2050.0
  site.region=3 if index==0 else 2;site.guarded=index==0
  site.reward=int(trails.rules.combat_reward) if index==0 else int(config.chest_crystals)
  trails.sites.append(site)
 var unit: Trails.Unit=Trails.Unit.new();unit.slot=0;unit.target_x=trails.sites[0].x;trails.units.append(unit)
