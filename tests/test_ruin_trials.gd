extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const PATH="res://domain/ruin_trials.gd"
func test_ruins_require_exploration_and_keep_checkpoint_progress(t):
 t.truth(ResourceLoader.exists(PATH),"ruins need playable trials rather than decorative markers")
 if not ResourceLoader.exists(PATH):return
 var config: Dictionary=load("res://data/campaign.tres").campaign_rules()
 config.seed=73
 config.economy=load("res://data/campaign.tres").economy_rules()
 var sim=Campaign.new(config)
 t.equal(sim.trials.sites.size(),2,"both distant module ruins have a challenge")
 var trial=sim.trials.sites[0]
 for region in sim.frontier.regions:region.discovered=true
 sim.modules.observe(sim,trial.x,430)
 t.truth(sim.modules.found.is_empty(),"walking over a sealed module cannot collect it")
 var before: int=sim.pouch.amount
 var wrong: int=(trial.order[0]+1)%3
 t.truth(sim.interact(trial.positions[wrong],"trial:%s:%d"%[trial.id,wrong]),"nearby rune uses the ordinary interaction command")
 t.equal(trial.progress,0,"incorrect rune resets sequence without charging crystals")
 t.equal(sim.pouch.amount,before,"retrying a ruin is free")
 for index: int in range(2):
  var station: int=trial.order[index]
  t.truth(sim.interact(trial.positions[station],"trial:%s:%d"%[trial.id,station]),"correct rune progresses the circuit")
 var codec=Codec.new()
 var saved: Dictionary=codec.capture(sim,config,{"x":trial.x,"y":430.0,"vx":0.0,"vy":0.0})
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not loaded.is_empty(),"partially completed ruin survives JSON save and load")
 if loaded.is_empty():return
 t.equal(loaded.session.trials.capture(),sim.trials.capture(),"saved circuit order and progress are preserved")
 var last: int=trial.order[2]
 for session in [sim,loaded.session]:
  t.truth(session.interact(trial.positions[last],"trial:%s:%d"%[trial.id,last]),"last rune breaks the seal")
  session.modules.observe(session,trial.x,430)
  session.modules.observe(session,trial.x,430)
  t.equal(session.modules.found.count(trial.id),1,"solved ruin grants existing module exactly once")
 t.equal(sim.trials.capture(),loaded.session.trials.capture(),"continuing after save matches uninterrupted play")
 var corrupt: Dictionary=saved.duplicate(true)
 corrupt.trials[0].progress=4
 t.truth(codec.restore(corrupt).is_empty(),"impossible puzzle progress is rejected")
 var old: Dictionary=saved.duplicate(true)
 old.version=14;preload("res://tests/legacy_checkpoint.gd").before_mount(old);old.erase("trials")
 for key in old.config.keys():
  if str(key).begins_with("ruin_"):old.config.erase(key)
 var legacy: Dictionary=codec.restore(old)
 t.truth(not legacy.is_empty(),"version 14 remains loadable")
 if not legacy.is_empty():t.truth(legacy.session.trials.sites.is_empty(),"old journeys are not retroactively locked")
func test_relay_times_out_and_same_seed_keeps_layout(t):
 if not ResourceLoader.exists(PATH):t.truth(false,"trial rules missing");return
 var config: Dictionary=load("res://data/campaign.tres").campaign_rules()
 config.seed=37;config.economy=load("res://data/campaign.tres").economy_rules()
 var a=Campaign.new(config);var b=Campaign.new(config)
 t.equal(a.trials.sites[0].order,b.trials.sites[0].order,"same seed produces same rune order")
 t.equal(a.trials.sites[0].positions,b.trials.sites[0].positions,"same seed keeps physical puzzle positions")
 var trial=a.trials.sites[1]
 for region in a.frontier.regions:region.discovered=true
 var station: int=trial.order[0]
 t.truth(not a.interact(trial.positions[station]+200,"trial:%s:%d"%[trial.id,station]),"remote rune cannot be activated")
 a.interact(trial.positions[station],"trial:%s:%d"%[trial.id,station])
 t.truth(trial.deadline>0,"relay starts a bounded deadline")
 var codec=Codec.new();var saved: Dictionary=codec.capture(a,config,{"x":trial.x,"y":430.0,"vx":0.0,"vy":0.0})
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not loaded.is_empty(),"running relay deadline can be saved")
 if loaded.is_empty():return
 var deadline: int=trial.deadline
 for session in [a,loaded.session]:session.trials.advance(deadline)
 t.equal(trial.progress,0,"expired relay resets instead of trapping the reward")
 t.equal(a.trials.capture(),loaded.session.trials.capture(),"relay timeout is identical after loading")
 for index: int in trial.order:a.trials.activate(trial.id,index,deadline)
 t.truth(a.trials.unlocked(trial.id),"expired relay can be retried successfully")
func test_terminal_tick_does_not_leave_an_expired_unsavable_relay(t):
 var config: Dictionary=load("res://data/campaign.tres").campaign_rules()
 config.seed=73;config.crystal_survival=0
 config.economy=load("res://data/campaign.tres").economy_rules()
 var sim=Campaign.new(config)
 var site=sim.trials.sites[1]
 for region in sim.frontier.regions:region.discovered=true
 var x: float=site.positions[0]
 sim.interact(x,"trial:%s:0"%site.id)
 sim.workforce.elapsed=float(site.deadline-1)/30
 sim.hero.hp=1
 var enemy: Dictionary=sim._spawn_raider()
 enemy.x=x+20;enemy.side=1;enemy.windup=0.001;enemy.target={"kind":"hero","x":x}
 sim.raiders.append(enemy)
 sim.advance(0.1,x)
 t.equal(sim.mission.outcome,"defeat","the terminal tick is a real lethal hit")
 var codec=Codec.new()
 var saved: Dictionary=codec.capture(sim,config,{"x":x,"y":430.0,"vx":0.0,"vy":0.0})
 t.truth(not codec.restore(JSON.parse_string(JSON.stringify(saved))).is_empty(),"dying as the relay expires remains a valid save")
