extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func rules() -> Dictionary:
 var config: Dictionary=preload("res://data/campaign_tuning.gd").new().campaign_rules()
 config.seed=741
 return config
func run() -> RefCounted:
 var sim=Campaign.new(rules())
 sim.world.people.clear()
 return sim
func enemy_at(sim, x: float, side: int=1) -> Dictionary:
 var enemy: Dictionary=sim._spawn_raider()
 enemy.x=x;enemy.side=side;enemy.exit_x=sim.mission.entry_x(side)
 sim.raiders.append(enemy)
 return enemy
func hit(sim, x: float=800.0) -> void:
 var enemy: Dictionary=enemy_at(sim,x+20)
 enemy.target={"kind":"hero","x":x};enemy.windup=0.001
 sim.advance(0.016,x)
 sim.raiders.clear()

func test_crystals_then_sword_then_life_on_actual_enemy_hit(t) -> void:
 var sim=run()
 t.equal(sim.pouch.capacity,30,"new journey holds thirty crystals")
 sim.interact(30,"hall")
 sim.pouch.amount=2
 hit(sim)
 t.truth(sim.hero.is_alive(),"last crystals absorb the hit even if damage is lethal")
 t.equal(sim.pouch.amount,0,"hit spills the remaining crystals")
 t.equal(sim.pouch.ground_total(),2,"spilled crystals remain physical resources")
 t.truth(sim.can_wield_sword(),"emptying pouch does not also remove sword")
 var count: int=sim.pouch.ground_total()
 hit(sim)
 t.truth(sim.can_wield_sword() and sim.pouch.ground_total()==count,"invulnerability prevents repeated loss")
 sim.hero.invulnerability_remaining=0;hit(sim)
 t.truth(sim.hero.is_alive() and not sim.can_wield_sword(),"next separate hit disarms knight")
 sim.hero.invulnerability_remaining=0;hit(sim)
 t.truth(not sim.hero.is_alive(),"empty unarmed knight dies on next hit")

func test_offering_cancels_attack_and_enemy_exits_without_reward(t) -> void:
 var sim=run()
 var enemy: Dictionary=enemy_at(sim,800)
 enemy.windup=0.5;enemy.target={"kind":"hero","x":820.0}
 sim.pouch.drop(2,800);sim.pouch.drops[0].age=1.0
 sim.advance(0.016,820)
 t.equal(enemy.get("carried_crystals",0),1,"small raider takes exactly one crystal")
 t.equal(enemy.windup,0.0,"offering cancels queued hostile attack")
 t.equal(sim.pouch.ground_total(),1,"remaining crystal remains available")
 var before: float=enemy.x
 sim.advance(0.1,820)
 t.truth(enemy.x>before,"right-side enemy returns toward its own portal")
 enemy.x=sim.mission.entry_x(1)-1
 var wallet: int=sim.pouch.amount
 sim.advance(0.016,820)
 t.truth(sim.raiders.is_empty(),"carrier disappears at portal")
 t.equal(sim.pouch.amount,wallet,"escaped carrier gives no kill reward")

func test_left_carrier_and_killed_carrier_conserve_crystals(t) -> void:
 var sim=run()
 var enemy: Dictionary=enemy_at(sim,-800,-1)
 sim.pouch.drop(1,-800);sim.pouch.drops[0].age=1
 sim.advance(0.016,2000);sim.advance(0.1,2000)
 t.truth(enemy.x < -800,"left-side raider retreats left")
 enemy.fighter.hp=0;sim.advance(0.016,2000)
 t.equal(sim.pouch.ground_total(),1,"killed carrier drops stolen crystal")

func test_dragon_hit_uses_crystal_protection(t) -> void:
 var sim=run()
 var dragon: Dictionary=enemy_at(sim,800)
 dragon.kind="dragon";dragon.windup=0.001;dragon.target={"kind":"hero","x":820.0}
 sim.pouch.amount=1
 sim.advance(0.016,820)
 t.truth(sim.hero.is_alive() and sim.pouch.amount==0,"dragon breath uses same crystal protection")
 t.equal(dragon.get("carried_crystals",0),0,"dragon does not take bribes")

func test_disarmed_and_carrier_state_survives_save_resume(t) -> void:
 var sim=run()
 sim.interact(30,"hall");sim.pouch.amount=0;hit(sim)
 var carrier: Dictionary=enemy_at(sim,-800,-1)
 sim.pouch.drop(1,-800);sim.pouch.drops[-1].age=1
 for i in range(10):sim.advance(1.0/60,2000)
 var codec=Codec.new()
 var body: Dictionary={"x":2000.0,"y":430.0,"vx":0.0,"vy":0.0}
 var saved: Dictionary=codec.capture(sim,rules(),body)
 var restored: Dictionary=codec.restore(saved)
 t.truth(not restored.is_empty(),"disarmed run and carrier can be loaded")
 if restored.is_empty():return
 t.truth(restored.session.survival.sword_on_ground and not restored.session.can_wield_sword(),"loading retains physical lost sword")
 for i in range(20):
  sim.advance(1.0/60,2000);restored.session.advance(1.0/60,2000)
 t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(codec.capture(sim,rules(),body),codec.capture(restored.session,rules(),body)),"save/resume matches uninterrupted retreat and sword timers across JSON numeric normalization")
 var corrupt: Dictionary=saved.duplicate(true)
 corrupt.survival.sword_grace=-1
 t.truth(codec.restore(corrupt).is_empty(),"invalid sword timer is rejected")

func test_sword_can_be_recovered_after_drop_grace(t) -> void:
 var sim=run()
 sim.interact(30,"hall");sim.pouch.amount=0;hit(sim)
 var at: float=sim.survival.sword_x
 sim.advance(0.1,at)
 t.truth(not sim.can_wield_sword(),"dropped sword cannot snap back immediately")
 for i in range(90):sim.advance(1.0/60,at)
 t.truth(sim.can_wield_sword() and not sim.survival.sword_on_ground,"returning to sword restores weapon after landing")

func test_v7_immersive_journey_migrates_to_crystal_survival(t) -> void:
 var old_rules: Dictionary={"seed":741,"immersive_loop":1,"capacity":12}
 var sim=Campaign.new(old_rules);sim.interact(30,"hall")
 var codec=Codec.new()
 var saved: Dictionary=codec.capture(sim,old_rules,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 saved.version=7;saved.erase("spirit");saved.erase("survival")
 var restored: Dictionary=codec.restore(saved)
 t.truth(not restored.is_empty(),"known v7 checkpoint upgrades")
 if restored.is_empty():return
 t.truth(restored.session.survival.enabled and restored.session.can_wield_sword(),"lit v7 camp preserves acquired weapon")
 t.equal(restored.session.pouch.capacity,30,"v7 immersive pouch upgrades to thirty without discarding crystals")
 t.equal(restored.session.pouch.amount,sim.pouch.amount,"upgrade preserves current wallet")

func test_identical_seed_and_offering_inputs_repeat(t) -> void:
 var a=run();var b=run()
 for sim in [a,b]:
  enemy_at(sim,-800,-1);enemy_at(sim,800,1)
  sim.pouch.drop(1,-780);sim.pouch.drop(1,780)
  for i in range(120):sim.advance(1.0/60,2000)
 var codec=Codec.new();var body: Dictionary={"x":2000.0,"y":430.0,"vx":0.0,"vy":0.0}
 t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(codec.capture(a,rules(),body),codec.capture(b,rules(),body)),"same seed and bait give same movement, money and combat state")

func test_corrupt_v7_wallet_is_not_repaired_by_larger_capacity(t) -> void:
 var old_rules: Dictionary={"seed":741,"immersive_loop":1,"capacity":12}
 var sim=Campaign.new(old_rules)
 var codec=Codec.new()
 var saved: Dictionary=codec.capture(sim,old_rules,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 saved.version=7;saved.erase("spirit");saved.erase("survival");saved.pouch.amount=13
 t.truth(codec.restore(saved).is_empty(),"v7 overflow corruption is rejected before capacity migration")
