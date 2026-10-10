extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const BODY={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
func config(planet: int) -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var value: Dictionary=tuning.campaign_rules();value.economy=tuning.economy_rules();value.seed=73;value.planet_id=planet
 return value
func fresh(planet: int) -> RefCounted:
 var sim: RefCounted=Campaign.new(config(planet))
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 return sim
func mechanism(sim: RefCounted, t: SceneTree) -> RefCounted:
 var site: RefCounted=sim.trials.sites[0]
 var result: Variant=site.get("mechanism")
 t.truth(result!=null,"later worlds need a real mechanism, not another printed rune sequence")
 return result
func press(sim: RefCounted, station: int) -> bool:
 var site: RefCounted=sim.trials.sites[0]
 return sim.interact(site.positions[station],"trial:%s:%d"%[site.id,station])
func test_sand_switches_change_neighbors_and_open_only_when_all_lit(t: SceneTree) -> void:
 var sim: RefCounted=fresh(1);var m: RefCounted=mechanism(sim,t)
 if m==null:return
 var site: RefCounted=sim.trials.sites[0];var coins: int=sim.pouch.amount
 t.equal(m.value,0,"sand circuit begins unpowered")
 press(sim,0)
 t.equal(m.value,3,"first switch toggles itself and its neighbor")
 t.truth(not sim.trials.unlocked(site.id),"one corrected lamp does not unlock reward")
 press(sim,2)
 t.truth(sim.trials.unlocked(site.id),"observing coupled switches can light all three lamps")
 sim.modules.observe(sim,site.x,430);sim.modules.observe(sim,site.x,430)
 t.equal(sim.modules.found.count(site.id),1,"opened mechanism grants its planet reward once")
 t.equal(sim.pouch.amount,coins,"experiments cost no crystals")
func test_balance_needs_both_controls_and_deliberate_lock(t: SceneTree) -> void:
 for planet: int in [2,4]:
  var sim: RefCounted=fresh(planet);var m: RefCounted=mechanism(sim,t)
  if m==null:continue
  var site: RefCounted=sim.trials.sites[0]
  press(sim,2)
  t.truth(not sim.trials.unlocked(site.id),"locking outside the target band does nothing")
  var actions: Array[int]=[]
  actions.assign([0,0,1] if planet==2 else [1,1,0])
  for station: int in actions:press(sim,station)
  t.truth(not sim.trials.unlocked(site.id),"balanced gauge waits for final confirmation")
  var codec: RefCounted=Codec.new();var saved: Dictionary=codec.capture(sim,config(planet),BODY)
  var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
  t.truth(not loaded.is_empty(),"partially adjusted thermal control survives save")
  if loaded.is_empty():continue
  press(sim,2);press(loaded.session,2)
  t.truth(sim.trials.unlocked(site.id),"both heating and cooling reach the marked band")
  t.equal(sim.trials.capture(),loaded.session.trials.capture(),"reload retains the same puzzle outcome")
func test_pulse_rejects_dark_window_but_keeps_completed_stations(t: SceneTree) -> void:
 var sim: RefCounted=fresh(5);var m: RefCounted=mechanism(sim,t)
 if m==null:return
 var site: RefCounted=sim.trials.sites[0]
 sim.workforce.elapsed=3.0;press(sim,0)
 t.equal(site.progress,0,"dark pulse cannot be brute forced into progress")
 sim.workforce.elapsed=6.0;press(sim,0)
 t.equal(site.progress,1,"visible pulse window allows charge")
 press(sim,0)
 t.equal(site.progress,1,"repeated same station cannot duplicate progress")
 sim.workforce.elapsed=9.0;press(sim,0)
 t.equal(site.progress,1,"a missed beat never erases a charged station")
 var codec: RefCounted=Codec.new();var saved: Dictionary=codec.capture(sim,config(5),BODY)
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not loaded.is_empty(),"pulse progress and world clock survive save")
 if loaded.is_empty():return
 for other: RefCounted in [sim,loaded.session]:
  other.workforce.elapsed=10.0;press(other,1)
  other.workforce.elapsed=14.0;press(other,2)
 t.truth(sim.trials.unlocked(site.id),"each station gets a readable timing opportunity")
 t.equal(sim.trials.capture(),loaded.session.trials.capture(),"pulse continues identically after loading")
func test_unseen_and_remote_mechanisms_cannot_be_operated(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new(config(3));var m: RefCounted=mechanism(sim,t)
 if m==null:return
 var site: RefCounted=sim.trials.sites[0];var key: String="trial:%s:0"%site.id
 var before: Array[Dictionary]=sim.trials.capture()
 t.truth(not sim.interact(site.positions[0],key),"undiscovered station is not actionable")
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 t.truth(not sim.interact(site.positions[0]+150,key),"distant station is not actionable")
 t.equal(sim.trials.capture(),before,"invalid actions change no puzzle state")
func test_corrupt_mechanisms_and_unsolvable_data_are_rejected(t: SceneTree) -> void:
 var codec: RefCounted=Codec.new()
 for planet: int in [1,2,5]:
  var sim: RefCounted=fresh(planet)
  var saved: Dictionary=codec.capture(sim,config(planet),BODY)
  var corrupt: Dictionary=saved.duplicate(true);corrupt.trials[0].mechanism.value=99
  t.truth(codec.restore(corrupt).is_empty(),"out of bounds mechanism value is protected")
  corrupt=saved.duplicate(true);corrupt.trials[0].progress=3
  t.truth(codec.restore(corrupt).is_empty(),"unearned unlock cannot be injected")
  corrupt=saved.duplicate(true);corrupt.trials[0].mechanism.marks=99
  t.truth(codec.restore(corrupt).is_empty(),"invalid charge mask is protected")
  corrupt=saved.duplicate(true);corrupt.config.erase("mechanism_1_mask_0")
  t.truth(codec.restore(corrupt).is_empty(),"missing data has no silent defaults")
 var bad: Dictionary=config(1)
 for i: int in range(3):bad["mechanism_1_mask_"+str(i)]=1
 t.truth(not preload("res://domain/ruin_trials.gd").valid_config(bad),"impossible circuit configuration is rejected")
 bad=config(2);bad.mechanism_2_warm=2;bad.mechanism_2_cool=-2
 t.truth(not preload("res://domain/ruin_trials.gd").valid_config(bad),"unreachable temperature parity is rejected")
func test_v17_partial_ruins_keep_original_rules_and_can_finish(t: SceneTree) -> void:
 var rules: Dictionary=config(2)
 for key: String in rules.keys():
  if key.begins_with("mechanism_"):rules.erase(key)
 var sim: RefCounted=Campaign.new(rules);var site: RefCounted=sim.trials.sites[0]
 sim.trials.activate(site.id,site.order[0],0)
 var codec: RefCounted=Codec.new();var saved: Dictionary=codec.capture(sim,rules,BODY);saved.version=17
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not loaded.is_empty(),"actual v17 shape remains playable")
 if loaded.is_empty():return
 var old: RefCounted=loaded.session.trials.sites[0]
 t.truth(old.mechanism==null,"old planet never replaces an in-progress sequence")
 t.equal(old.progress,1,"existing partial progress is retained")
 for index: int in [1,2]:loaded.session.trials.activate(old.id,old.order[index],0)
 t.truth(loaded.session.trials.unlocked(old.id),"old sequence can still finish")
 t.equal(codec.capture(loaded.session,loaded.config,BODY).version,18,"old game resaves in current format")
 var unknown: Dictionary=saved.duplicate(true);unknown.version=999
 t.truth(codec.restore(unknown).is_empty(),"unknown future saves remain protected")
func test_every_world_preserves_partial_progress_and_solutions(t: SceneTree) -> void:
 for planet: int in range(1,7):
  var a: RefCounted=fresh(planet);var site: RefCounted=a.trials.sites[0]
  if planet in [1,3]:press(a,2)
  elif planet in [2,4]:press(a,0)
  else:a.workforce.elapsed=8.0;press(a,0)
  var codec: RefCounted=Codec.new();var packet: Dictionary=codec.capture(a,config(planet),BODY)
  var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
  t.truth(not restored.is_empty(),"each family preserves its incomplete state: "+str(planet))
  if restored.is_empty():continue
  for i: int in range(15):a.advance(1.0/30,30);restored.session.advance(1.0/30,30)
  t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(codec.capture(a,config(planet),BODY),codec.capture(restored.session,config(planet),BODY)),"save-then-play equals uninterrupted core state")
  var b: RefCounted=fresh(planet)
  preload("res://tests/ruin_solution.gd").solve(b,planet)
  t.truth(b.trials.unlocked(site.id),"authored route solves this destination")
  b.modules.observe(b,site.x,430)
  t.equal(b.modules.equipped,site.id,"opened reward still uses ordinary collection")
