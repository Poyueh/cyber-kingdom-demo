extends SceneTree
## Accelerated 30-minute simulation; diagnostics only, never a claim of iPhone stability.
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const STEP: float=1.0/30
var _codec: RefCounted=Codec.new()
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var config: Dictionary={"seed":42,"immersive_loop":1,"day_seconds":180.0}
 var sim=Campaign.new(config)
 sim.frontier.city_level=3;sim.frontier.farm_active=true
 for i in range(sim.world.people.size()):sim.world.people[i].role="farmer" if i%2 else "engineer"
 for region in sim.frontier.regions:region.discovered=true
 for node in sim.frontier.nodes:
  if node.kind!="cache":node.marked=true
 print("minutes,memory_bytes,objects,drops,loot,effects,save_bytes,save_us")
 for tick in range(54001):
  var x: float=sim.frontier.left_boundary+fposmod(tick*3.0,sim.frontier.right_boundary-sim.frontier.left_boundary)
  sim.hero.hp=sim.hero.stats.max_hp;sim.mission.core_hp=sim.mission.core_max_hp;sim.mission.outcome="active"
  for enemy in sim.raiders:enemy.fighter.hp=0
  sim.advance(STEP,x)
  if tick%120==0:sim.pouch.burst(3,sim.world.sites.farm)
  if tick%9000!=0:continue
  var start: int=Time.get_ticks_usec()
  var packet: Dictionary=_codec.capture(sim,config,{"x":x,"y":430.0,"vx":0.0,"vy":0.0})
  var restored: Dictionary=_codec.restore(packet)
  if restored.is_empty():printerr("FAIL: soak snapshot restore: ",_codec.last_error);quit(1);return
  print("%d,%d,%d,%d,%d,%d,%d,%d"%[tick/1800,OS.get_static_memory_usage(),Performance.get_monitor(Performance.OBJECT_COUNT),sim.pouch.drops.size(),sim.loot.size(),sim.effects.size(),JSON.stringify(packet).length(),Time.get_ticks_usec()-start])
 print("PASS: 30-minute accelerated simulation and seven save restores")
 quit()
