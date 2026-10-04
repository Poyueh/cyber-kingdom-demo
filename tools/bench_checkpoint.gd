extends SceneTree
## Native CPU microbenchmark; excludes rendering, JSON serialization and disk I/O.
## Same seed/configuration and three repeats for before/after comparisons.
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var tuning=load("res://data/campaign.tres")
 var config: Dictionary={"economy":tuning.economy_rules(),"scrap":tuning.starting_scrap,"crystals":tuning.starting_crystals,"first_raid":tuning.first_raid_seconds,"raid_gap":tuning.raid_gap_seconds,"person_speed":tuning.resident_speed,"shield_value":tuning.shield_per_crystal}
 config.merge(tuning.campaign_rules(),true);config.seed=742601
 var sim=Campaign.new(config)
 var codec=Codec.new()
 var body: Dictionary={"x":0.0,"y":430.0,"vx":0.0,"vy":0.0}
 var packet: Dictionary=codec.capture(sim,config,body)
 if codec.restore(packet).is_empty():printerr(codec.last_error);quit(1);return
 print("nodes=",sim.frontier.nodes.size()," regions=",sim.frontier.regions.size())
 for repeat in range(3):
  var start: int=Time.get_ticks_usec()
  for i in range(100):codec.capture(sim,config,body)
  print("capture_us=",(Time.get_ticks_usec()-start)/100)
  start=Time.get_ticks_usec()
  for i in range(100):codec.restore(packet)
  print("restore_us=",(Time.get_ticks_usec()-start)/100)
  start=Time.get_ticks_usec()
  for i in range(1000):sim.context(0.0)
  print("context_us=",(Time.get_ticks_usec()-start)/1000)
  start=Time.get_ticks_usec()
  for i in range(1000):sim.advance(1.0/30,0.0)
  print("advance_us=",(Time.get_ticks_usec()-start)/1000)
 quit()
