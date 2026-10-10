extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const PATH="res://domain/mount_expedition.gd"
func config() -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var c: Dictionary=tuning.campaign_rules()
 c.seed=73;c.economy=tuning.economy_rules()
 return c
func test_mount_route_requires_circuit_recovery_and_paid_stable(t) -> void:
 t.truth(ResourceLoader.exists(PATH),"a recoverable mechanical mount is playable")
 if not ResourceLoader.exists(PATH):return
 var c: Dictionary=config();var sim=Campaign.new(c)
 var quest: RefCounted=sim.mount_quest
 sim.frontier.city_level=1;sim.survival.armed=true;sim.pouch.amount=30
 t.truth(not sim.interact(quest.ruin_x,"mount_recover"),"fog cannot be interacted through")
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 t.truth(not sim.interact(quest.ruin_x,"mount_recover"),"closed circuit cannot grant mount")
 for index: int in [0,1,1]:
  t.truth(sim.interact(quest.levers[index],"mount_lever:%d"%index),"each E turns one circuit junction")
 t.truth(quest.powered(),"aligned junctions conduct energy to the cradle")
 t.truth(sim.interact(quest.ruin_x,"mount_recover"),"powered cradle releases mount core")
 t.truth(not sim.mounted(),"recovery does not equip before stable is restored")
 var codec=Codec.new()
 var saved: Dictionary=codec.capture(sim,c,{"x":quest.ruin_x,"y":430.0,"vx":0.0,"vy":0.0})
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not restored.is_empty(),"recovered core and puzzle survive a checkpoint")
 if restored.is_empty():return
 for session: RefCounted in [sim,restored.session]:
  var at: float=session.mount_quest.stable_x
  for i: int in range(session.mount_quest.cost):t.truth(session.interact(at,"mount_stable"),"stable accepts incremental crystal payment")
  t.truth(session.mounted(),"completed stable equips the recovered mount")
  t.truth(session.interact(at,"mount_switch"),"stable allows free dismount")
  t.truth(not session.mounted(),"choice to travel on foot persists")
  t.truth(session.interact(at,"mount_switch"),"mount can be selected again")
 t.equal(sim.mount_quest.capture(),restored.session.mount_quest.capture(),"same commands after load produce same progress")
 var bad: Dictionary=saved.duplicate(true);bad.mount.rotations=[4,2]
 t.truth(codec.restore(bad).is_empty(),"impossible junction state is rejected")
 var old: Dictionary=saved.duplicate(true);old.version=15;preload("res://tests/legacy_checkpoint.gd").before_module_catalog(old);old.erase("mount")
 for key: String in old.config.keys():
  if key.begins_with("mount_"):old.config.erase(key)
 var legacy: Dictionary=codec.restore(old)
 t.truth(not legacy.is_empty(),"v15 journey loads without injecting a new quest")
 if not legacy.is_empty():t.truth(not legacy.session.mount_quest.enabled,"legacy difficulty is retained")
func test_raid_has_warning_gate_spawns_and_one_recovery_night(t) -> void:
 if not ResourceLoader.exists(PATH):t.truth(false,"mount expedition missing");return
 var sim=Campaign.new(config());var q: RefCounted=sim.mount_quest
 q.rotations.assign([1,2]);q.recover();q.restore_stable(0)
 t.equal(q.night_bonus(1,0),0,"raid cannot bypass the warning period")
 t.equal(q.night_bonus(2,q.warning_ticks),q.extra_enemies,"next eligible night gains one assault")
 t.equal(q.night_bonus(3,q.warning_ticks+600),-q.recovery_discount,"following night provides recovery")
 t.equal(q.night_bonus(4,q.warning_ticks+1200),0,"no repeated surprise assault")
 var other=Campaign.new(config());other.mount_quest.rotations.assign([1,2]);other.mount_quest.recover();other.mount_quest.restore_stable(0)
 other.workforce.elapsed=float(other.mount_quest.warning_ticks)/30
 other.clock.remaining=0.01
 other.advance(0.02,other.world.sites.hall)
 t.equal(other.raiders.size(),1,"assault enters through the regular paced spawner")
 t.truth(absf(other.raiders[0].x-other.mission.entry_x(1))<3,"first enemy materializes at its outer gate and begins moving inward")
 var codec=Codec.new();var data: Dictionary=codec.capture(other,config(),{"x":other.world.sites.hall,"y":430.0,"vx":0.0,"vy":0.0})
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(data)))
 t.truth(not loaded.is_empty(),"active assault saves and resumes")
 if loaded.is_empty():return
 for session: RefCounted in [other,loaded.session]:session.advance(2.6,session.world.sites.hall)
 t.equal(other.mount_quest.capture(),loaded.session.mount_quest.capture(),"raid stage continues identically after save")
 t.equal(other._spawn_remaining,loaded.session._spawn_remaining,"pending reinforcements are preserved")
func test_exploration_does_not_scale_dragons_forever(t) -> void:
 var rules: Dictionary=preload("res://domain/dragon_rules.gd").tuning(config())
 var dragon: Script=preload("res://domain/dragon_rules.gd")
 t.equal(dragon.strength(100,rules),dragon.strength(14,rules),"new journeys cap dragon escalation to allow exploration")
 var legacy: Dictionary=dragon.tuning({})
 t.truth(dragon.strength(100,legacy).health>dragon.strength(14,legacy).health,"old campaign balance is not changed")
func test_mount_travels_between_planets_without_repeating_forest_assault(t) -> void:
 var c: Dictionary=config();var forest=Campaign.new(c)
 forest.mount_quest.rotations.assign([1,2]);forest.mount_quest.recover();forest.mount_quest.restore_stable(0)
 var other_config: Dictionary=c.duplicate(true);other_config.planet_id=1
 var desert=Campaign.new(other_config)
 preload("res://application/planet_passenger.gd").carry(forest,desert)
 t.truth(desert.mounted(),"unlocked mount accompanies the knight to another world")
 t.equal(desert.mount_quest.night_bonus(8,90000),0,"the forest assault cannot repeat on other planets")
 var codec=Codec.new()
 var packet: Dictionary=codec.capture(desert,other_config,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 t.truth(not codec.restore(JSON.parse_string(JSON.stringify(packet))).is_empty(),"off-world mount survives save and load")
func test_losing_sword_dismounts_and_requires_sword_before_remount(t) -> void:
 var sim=Campaign.new(config());var q: RefCounted=sim.mount_quest
 sim.frontier.city_level=1;sim.survival.armed=true
 q.rotations.assign([1,2]);q.recover();q.restore_stable(0)
 sim.survival.armed=false
 sim.advance(0.05,sim.world.sites.hall)
 t.truth(not sim.mounted(),"losing the sword forces a vulnerable rider onto foot")
 t.truth(not sim.interact(q.stable_x,"mount_switch"),"unarmed knight cannot show a mounted sword pose")
 sim.survival.armed=true
 t.truth(sim.interact(q.stable_x,"mount_switch"),"recovering the sword allows remounting at the stable")
