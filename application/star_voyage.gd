extends RefCounted
## Seven bounded snapshots, only one live simulation. Travel is prepared on copies;
## bootstrap persists the candidate before replacing the live world.
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Streams=preload("res://domain/rng/rng_streams.gd")
const Passenger=preload("res://application/planet_passenger.gd")
const Operations=preload("res://application/planet_operations.gd")
var current: int=0
var configs: Array[Dictionary]=[]
const WORLD_COUNT: int = 7
var planets: Array[Dictionary]=[{}, {}, {}, {}, {}, {}, {}]
func _init(base: Dictionary={}, profiles: Array[Dictionary]=[]) -> void:
 if base.is_empty():return
 var random: RandomNumberGenerator=Streams.new(int(base.seed)).of(Streams.Stream.WORLD)
 for id: int in range(WORLD_COUNT):
  var config: Dictionary=base.duplicate(true)
  if profiles.size()==WORLD_COUNT:config.merge(profiles[id],true)
  config.planet_id=id;config.voyage_enabled=1
  config.seed=base.seed if id==0 else random.randi_range(1,2000000000)
  config.economy=config.get("economy",{}).duplicate(true)
  config.economy.planet_id=id
  if id>0:config.starting_crystals=0
  configs.append(config)
func core_count(sim: RefCounted) -> int:
 var count: int=0
 for id: int in range(planets.size()):
  if id==current:
   if sim.planet.core_claimed:count+=1
  elif not planets[id].is_empty() and planets[id].planet.core_claimed:count+=1
 return count
func observe(sim: RefCounted) -> void:
 if core_count(sim)>0:sim.planet.reactor=true
 if core_count(sim)==WORLD_COUNT:
  sim.planet.completed=true
  sim.mission.resolve(sim.hero.is_alive(),sim.raiders.is_empty())
func capture(sim: RefCounted, body: Dictionary) -> Dictionary:
 var worlds: Array[Dictionary]=planets.duplicate(true)
 worlds[current]={"campaign":Codec.new().capture(sim,configs[current],body),"planet":sim.planet.capture()}
 return {"format":"seven_planets" if planets.size()==WORLD_COUNT else "three_planets","version":2 if planets.size()==WORLD_COUNT else 1,"current":current,"configs":configs.duplicate(true),"planets":worlds}
static func restore(raw: Variant) -> Dictionary:
 if not raw is Dictionary or raw.size()!=5:return {}
 var count: int = WORLD_COUNT if raw.get("format")=="seven_planets" and raw.get("version")==2 else 3 if raw.get("format")=="three_planets" and raw.get("version")==1 else 0
 if count==0:return {}
 var packet: Dictionary=Codec.new()._normalize(raw)
 if not packet.get("current") is int or packet.current<0 or packet.current>=count or not packet.get("configs") is Array or not packet.get("planets") is Array:return {}
 if packet.configs.size()!=count or packet.planets.size()!=count:return {}
 var voyage=load("res://application/star_voyage.gd").new()
 voyage.current=packet.current
 voyage.planets.resize(count)
 var active: Dictionary={}
 var cores: int=0
 for id: int in range(count):
  var config: Variant=packet.configs[id]
  if not config is Dictionary or not preload("res://application/campaign_checkpoint_rules.gd").config_valid(config):return {}
  if config.get("planet_id")!=id or config.get("voyage_enabled")!=1:return {}
  voyage.configs.append(config.duplicate(true))
  var world: Variant=packet.planets[id]
  if not world is Dictionary:return {}
  voyage.planets[id]=world.duplicate(true)
  if world.is_empty():continue
  if world.size()!=2 or not world.has("campaign") or not world.has("planet"):return {}
  var restored: Dictionary=Codec.new().restore(world.campaign)
  if restored.is_empty() or not preload("res://application/campaign_checkpoint_rules.gd").same(restored.config,config):return {}
  if not restored.session.planet.restore(world.planet):return {}
  if restored.session.planet.cleared and not restored.session.mission.dragon_defeated:return {}
  if restored.session.planet.core_claimed:cores+=1
  if id==packet.current:active=restored
 if active.is_empty() or (packet.current!=0 and cores==0):return {}
 for world: Dictionary in voyage.planets:
  if not world.is_empty() and world.planet.completed and cores!=count:return {}
 active.journey=voyage
 voyage.observe(active.session)
 return active
func prepare(sim: RefCounted, body: Dictionary, target: int) -> Dictionary:
 if target<0 or target>=planets.size() or target==current or not sim.is_running() or not sim.can_wield_sword():return {}
 if not accessible(target,sim):return {}
 if not sim.planet.rocket_ready or core_count(sim)==0 or not sim.raiders.is_empty():return {}
 if absf(body.x-Operations.rocket_x(sim))>=90:return {}
 var copied: Dictionary=restore(capture(sim,body))
 if copied.is_empty():return {}
 var next: RefCounted=copied.journey
 var arrival: Dictionary
 if next.planets[target].is_empty():
  arrival={"session":Campaign.new(next.configs[target]),"config":next.configs[target],"body":{"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}}
 else:
  arrival=Codec.new().restore(next.planets[target].campaign)
  arrival.session.planet.restore(next.planets[target].planet)
 Passenger.carry(sim,arrival.session)
 next.current=target
 arrival.session.planet.reactor=true;arrival.session.planet.wrecked=true
 arrival.session.planet.rocket_ready=false;arrival.session.planet.rocket_pending=false;arrival.session.planet.work=0.0
 arrival.body={"x":Operations.rocket_x(arrival.session)+110,"y":430.0,"vx":0.0,"vy":0.0}
 next.observe(arrival.session)
 arrival.journey=next
 return arrival

## A visited colony is always a return route. New sectors need every linked core.
func has_core(id: int, sim: RefCounted) -> bool:
 if id==current:return sim.planet.core_claimed
 return not planets[id].is_empty() and planets[id].planet.core_claimed
func required_mask(id: int) -> int:
 return int(configs[id].get("route_requires", 0 if id==0 else 1))
func accessible(id: int, sim: RefCounted) -> bool:
 if id<0 or id>=planets.size():return false
 if id==current or not planets[id].is_empty():return true
 var mask: int=required_mask(id)
 for source: int in range(planets.size()):
  if mask & (1<<source) and not has_core(source,sim):return false
 return true
## Called only at the composition boundary after a fully validated legacy load.
## Keep old layouts/configs byte-equivalent; only append new content definitions.
func expand(profiles: Array[Dictionary], sim: RefCounted) -> void:
 if configs.size()!=3 or profiles.size()!=WORLD_COUNT:return
 var extended: RefCounted=load("res://application/star_voyage.gd").new(configs[0],profiles)
 for id: int in range(3,WORLD_COUNT):
  configs.append(extended.configs[id]);planets.append({})
 for world: Dictionary in planets:
  if world.is_empty():continue
  world.planet.completed=false
  if world.campaign.mission.outcome=="victory":world.campaign.mission.outcome="active"
 sim.planet.completed=false
 if sim.mission.outcome=="victory":sim.mission.outcome="active"
 observe(sim)
