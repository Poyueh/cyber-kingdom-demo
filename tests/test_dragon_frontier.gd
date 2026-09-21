extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func summoned(day: int):
 var sim=Campaign.new({"seed":7})
 sim.clock.day=day;sim.clock.survived=day-1
 sim.world.people.clear()
 for r in sim.mission.rifts:r.sealed=true
 sim.advance(0.01,30)
 return sim
func test_two_gates_summon_a_dragon_instead_of_winning(t):
 var sim=summoned(2)
 t.equal(sim.mission.outcome,"active","sealing both gates starts final battle")
 var dragons=sim.raiders.filter(func(e):return e.get("kind","")=="dragon")
 t.equal(dragons.size(),1,"exactly one real dragon enemy is summoned")
 if dragons.is_empty():return
 var hp=dragons[0].fighter.hp
 sim.advance(0.01,30)
 t.equal(sim.raiders.size(),1,"subsequent frames never duplicate dragon")
 t.truth(hp>=1000,"dragon requires sustained army support")
 dragons[0].fighter.hp=0;sim.advance(0.01,30)
 t.equal(sim.mission.outcome,"victory","defeating final dragon completes run")
func test_dragon_has_floor_and_late_growth(t):
 var early=summoned(2);var baseline=summoned(6);var late=summoned(9)
 if early.raiders.is_empty() or baseline.raiders.is_empty() or late.raiders.is_empty():
  t.truth(false,"dragon exists for every summoning day");return
 t.equal(early.raiders[0].fighter.hp,baseline.raiders[0].fighter.hp,"summoning before day six cannot weaken base dragon")
 t.truth(late.raiders[0].fighter.hp>baseline.raiders[0].fighter.hp,"delaying beyond baseline strengthens dragon")
 t.truth(late.raiders[0].fighter.stats.damage>baseline.raiders[0].fighter.stats.damage,"late dragon also hits harder")
func test_dragon_save_resume_and_army_damage(t):
 var sim=summoned(7)
 if sim.raiders.is_empty():t.truth(false,"dragon available");return
 var dragon=sim.raiders[0];dragon.x=500;dragon.cooldown=10
 sim.world.people.append({"x":450.0,"role":"hunter","hurt":0.0,"cooldown":0.0,"region":-1})
 var hp=dragon.fighter.hp
 sim.advance(0.01,30)
 t.truth(dragon.fighter.hp<hp,"resident weapons damage actual dragon")
 var codec=Codec.new();var packet=codec.capture(sim,{"seed":7},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 var restored=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not restored.is_empty(),"active boss survives real JSON roundtrip")
 if restored.is_empty():return
 t.equal(restored.session.raiders[0].fighter.hp,dragon.fighter.hp,"boss health is not reset on load")
 restored.session.advance(0.01,30)
 t.equal(restored.session.raiders.size(),1,"loading does not summon duplicate boss")
func test_idle_workers_and_guards_patrol(t):
 var sim=Campaign.new({"seed":7});sim.world.people.clear()
 sim.world.people.append({"x":30.0,"role":"engineer","hurt":0.0,"cooldown":0.0,"region":-1})
 for i in range(400):sim.advance(0.02,100)
 t.truth(sim.world.people[0].get("walk_distance",0)>20,"idle engineer strolls instead of freezing")

func test_concurrent_resident_volley_is_not_discarded(t):
 var sim=summoned(6)
 if sim.raiders.is_empty():t.truth(false,"dragon available for volley");return
 var dragon=sim.raiders[0];dragon.x=500;dragon.cooldown=10
 for i in range(3):sim.world.people.append({"x":450.0,"role":"hunter","hurt":0.0,"cooldown":0.0,"region":-1})
 var before: int=dragon.fighter.hp
 sim.advance(0.01,30)
 t.equal(before-dragon.fighter.hp,36,"three simultaneous archer arrows all contribute damage")

func test_v3_completed_run_remains_completed_and_active_run_gets_boss(t):
 var codec=Codec.new()
 for won in [false,true]:
  var sim=Campaign.new({"seed":7,"flat_frontier":0,"fortifications":0})
  for r in sim.mission.rifts:r.sealed=true
  sim.mission.outcome="victory" if won else "active"
  var packet=codec.capture(sim,{"seed":7},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
  packet.session.erase("barracks_level")
  for field in ["buildings","build_seconds","tower_damage","tower_range"]:packet.session.erase(field)
  packet.erase("survival");packet.erase("travel");packet.version=3
  for field in ["dragon_summoned","dragon_defeated","dragon_day","dragon_rules"]:packet.mission.erase(field)
  var original=packet.duplicate(true)
  var restored=codec.restore(packet)
  t.truth(not restored.is_empty(),"known v3 run upgrades")
  t.equal(packet,original,"migration preserves original packet")
  if restored.is_empty():continue
  restored.session.advance(0.01,30)
  t.equal(restored.session.mission.outcome,"victory" if won else "active","earned legacy victory stays earned")
  t.equal(restored.session.raiders.size(),0 if won else 1,"only unfinished legacy run summons a boss")
