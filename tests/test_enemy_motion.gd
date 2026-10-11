extends RefCounted
const Motion = preload("res://presentation/raider_motion_view.gd")
const Campaign = preload("res://application/campaign_session.gd")

func test_enemy_animation_follows_distance_freezes_and_prunes(t: SceneTree) -> void:
	var sim: RefCounted = Campaign.new()
	var enemy: Dictionary = sim._spawn_raider()
	enemy.x = 500.0
	sim.raiders.append(enemy)
	var motion: RefCounted = Motion.new()
	motion.present(sim)
	var phase: float = motion.state_for(enemy).phase
	enemy.x += 14.0
	sim.workforce.elapsed += 0.1
	motion.present(sim)
	t.truth(motion.state_for(enemy).phase != phase,"moving changes the gait by travelled distance")
	phase = motion.state_for(enemy).phase
	motion.present(sim)
	t.equal(motion.state_for(enemy).phase,phase,"rendering a paused world cannot advance gait")
	enemy.fighter.hp = 0
	motion.present(sim)
	t.equal(motion.tracked_count(),0,"dead actors release animation memory")

func test_cancelled_windup_never_plays_a_phantom_claw_attack(t: SceneTree) -> void:
	var sim: RefCounted = Campaign.new()
	var enemy: Dictionary = sim._spawn_raider()
	enemy.windup = 0.5
	sim.raiders.append(enemy)
	var motion: RefCounted = Motion.new()
	motion.present(sim)
	enemy.windup = 0.0;enemy.stagger = 0.24
	sim.workforce.elapsed += 0.02
	motion.present(sim)
	t.truth(motion.state_for(enemy).strike_age > 1.0,"heavy interruption does not look like an enemy attack")
	enemy.stagger = 0.0;enemy.windup = 0.03
	sim.workforce.elapsed += 0.02;motion.present(sim)
	enemy.windup = 0.0
	sim.workforce.elapsed += 0.04;motion.present(sim)
	t.equal(motion.state_for(enemy).strike_age,0.0,"a completed windup releases the claw pose")

func test_dragon_multibeat_animates_actual_impacts_without_replaying_on_load(t: SceneTree) -> void:
	var sim: RefCounted = Campaign.new()
	var dragon: Dictionary = sim._spawn_raider()
	dragon.kind = "dragon";dragon.windup = 1.5
	sim.raiders.append(dragon)
	sim.effects.append({"kind":"planet_strike","x":30.0,"life":0.8})
	var motion: RefCounted = Motion.new();motion.present(sim)
	t.truth(motion.state_for(dragon).strike_age > 1.0,"opening a view mid-effect does not invent a new attack")
	sim.effects.append({"kind":"planet_strike","x":130.0,"life":0.85})
	sim.workforce.elapsed += 0.02;motion.present(sim)
	t.equal(motion.state_for(dragon).strike_age,0.0,"the next volley flashes its release even while next windup is positive")
	sim.workforce.elapsed += 0.10;motion.present(sim)
	t.truth(motion.state_for(dragon).strike_age > 0.09,"the same retained effect never retriggers release")
	var elapsed: float = motion.state_for(dragon).strike_age
	motion.present(sim)
	t.equal(motion.state_for(dragon).strike_age,elapsed,"pause freezes a dragon release")
	var second: RefCounted = Campaign.new();motion.present(second)
	t.equal(motion.tracked_count(),0,"changing journeys clears the previous boss state")
