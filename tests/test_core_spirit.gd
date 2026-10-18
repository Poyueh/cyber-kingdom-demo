extends "res://tests/test_core_loop.gd"
func _initialize() -> void:
 for main_game: bool in [false,true]:
  var config: Dictionary=configuration()
  if main_game:config=main_configuration()
  var sim: RefCounted=Campaign.new(config)
  ticks(sim,5400,sim.world.sites.hall)
  var hint: Dictionary=sim.spirit.advice(sim,sim.world.sites.hall)
  check(hint.get("kind")=="camp","unfinished ghost survives the old opening timeout")
  if hint.is_empty():continue
  check(hint.get("core",false),"ghost advice belongs to actual core onboarding")
  pay(sim,sim.world.sites.hall,"hall",1)
  check(sim.spirit.advice(sim,30).get("kind")=="recruit","lighting the camp changes the ghost's actual target")
  pay(sim,sim.world.people[0].x,"recruit:0",1)
  pay(sim,sim.world.sites.workshop,"workshop",2)
  ticks(sim,450,sim.world.sites.workshop)
  hint=sim.spirit.advice(sim,sim.world.sites.workshop)
  check(hint.get("kind")=="harvest" and sim.context_for_key(hint.x,hint.key).enabled,"ghost selects a real payable work-area tree")
  pay(sim,hint.x,hint.key,1)
  hint=sim.spirit.advice(sim,sim.world.sites.hall)
  check(hint.get("kind")=="work_income" and hint.action=="wait","paid work is observed instead of requested twice")
  ticks(sim,700,-100)
  hint=sim.spirit.advice(sim,-100)
  check(hint.get("kind")=="resident_income","ghost locates the actual harvest carrier before teaching defence")
  if hint.get("kind")=="resident_income":
   ticks(sim,100,hint.x)
   check(sim.core_loop.income>0,"following the ghost collects earned harvest, not a tutorial grant")
  var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
  var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
  var before: Dictionary=codec.capture(sim,config,body)
  for i: int in range(30):sim.spirit.advice(sim,30)
  check(Rules.same(before,codec.capture(sim,config,body)),"guidance never mutates money, progress, or random state")
  var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(before)))
  check(not restored.is_empty(),"existing v22 saves restore with guidance")
  if not restored.is_empty():check(Rules.same(restored.session.spirit.advice(restored.session,30),sim.spirit.advice(sim,30)),"reload points to the same real task")
  sim.core_loop.skipped=true
  check(sim.spirit.advice(sim,30).is_empty(),"skip dismisses the companion without completing lessons")
  sim.core_loop.skipped=false
  check(not sim.spirit.advice(sim,30).is_empty(),"show brings companion back to current task")
  sim.core_loop.stage=2
  check(sim.spirit.advice(sim,30).get("mood")=="guard","dusk switches companion to defensive warning")
  sim.core_loop.stage=3
  check(sim.spirit.advice(sim,30).get("mood")=="rest","independent preparation does not prescribe a new task")
  if main_game:
   sim.core_loop.skipped=true
   var shrine: float=sim.spirit.shrine_x(sim.world.sites.hall)
   var crystals: int=sim.pouch.amount
   check(sim.interact(shrine,"spirit"),"main-game shrine accepts a real paid recall during independent preparation")
   var recalled: Dictionary=sim.spirit.advice(sim,shrine)
   check(not recalled.is_empty() and not recalled.get("core",false),"explicit paid recall overrides quiet or skipped core guidance")
   check(sim.pouch.amount==crystals-1,"recall uses the existing one-crystal cost")
   ticks(sim,600,shrine)
   check(sim.spirit.advice(sim,shrine).is_empty(),"paid visit expires normally and keeps hidden core preference")
   sim.core_loop.skipped=false
  sim.core_loop.stage=5
  check(sim.spirit.advice(sim,30).is_empty(),"completed onboarding leaves the player free")
 print("Core spirit: %d assertions, %d failures"%[assertions,failures]);quit(1 if failures else 0)

func main_configuration() -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var base: Dictionary=tuning.campaign_rules()
 base.merge({"seed":1054,"economy":tuning.economy_rules()},true)
 base.level_design=load("res://data/planet_levels.tres").rules()
 base.trail_design=load("res://data/trail_encounters.tres").rules()
 base.ruin_variation=load("res://data/ruin_variation.tres").rules()
 var profiles: Array[Dictionary]=[]
 for name: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:profiles.append(load("res://data/planets/"+name+".tres").rules())
 var journey: RefCounted=load("res://application/journey_setup.gd").create(base,profiles,load("res://data/journey_paces.tres").find(0).rules())
 var profile: Resource=load("res://data/core_loop.tres")
 if profile.has_method("resolve_campaign"):
  for i: int in range(7):journey.configs[i]=profile.resolve_campaign(journey.configs[i])
 return journey.configs[0]
