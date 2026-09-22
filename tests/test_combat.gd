extends RefCounted
const Fighter = preload("res://domain/combatant.gd")
const Stats = preload("res://domain/combat_stats.gd")

func test_one_swing_hits_each_target_once(t) -> void:
	var hero = Fighter.new(Stats.new())
	var enemy = Fighter.new(Stats.new())
	t.truth(hero.start_attack(), "first swing starts")
	hero.advance(0.18)
	t.truth(hero.strike(enemy, 25.0), "front target receives hit")
	t.equal(enemy.hp, 75, "damage applied")
	t.equal(hero.strike(enemy, 25.0), false, "same swing cannot hit twice")
	t.equal(enemy.hp, 75, "duplicate hit does not change health")

func test_range_and_facing_do_not_consume_a_valid_hit(t) -> void:
	var hero = Fighter.new(Stats.new())
	var enemy = Fighter.new(Stats.new())
	hero.start_attack()
	hero.advance(0.18)
	t.equal(hero.strike(enemy, 200.0), false, "far target missed")
	t.equal(hero.strike(enemy, -25.0), false, "target behind missed")
	t.truth(hero.strike(enemy, 25.0), "target entering front arc can be hit")

func test_attack_window_and_cooldown(t) -> void:
	var hero = Fighter.new(Stats.new())
	var enemy = Fighter.new(Stats.new())
	hero.start_attack()
	hero.advance(0.3)
	t.equal(hero.strike(enemy, 25.0), false, "recovering sword cannot deal damage")
	t.equal(hero.start_attack(), false, "cooldown still active")
	hero.advance(0.2)
	t.truth(hero.start_attack(), "next swing starts after cooldown")

func test_dash_spends_stamina_and_protects_health(t) -> void:
	var hero = Fighter.new(Stats.new())
	t.truth(hero.start_dash(), "dash starts")
	t.equal(hero.stamina, 70.0, "dash spends stamina")
	t.equal(hero.take_damage(40), false, "dash is invulnerable")
	hero.advance(0.3)
	t.truth(hero.take_damage(40), "damage after dash accepted")
	t.equal(hero.hp, 60, "health changed")
	hero.stamina = 0
	t.equal(hero.start_dash(), false, "not enough stamina")

func test_death_and_invalid_damage(t) -> void:
	var hero = Fighter.new(Stats.new())
	t.equal(hero.take_damage(-50), false, "negative damage rejected")
	t.equal(hero.hp, 100, "negative damage cannot heal")
	hero.take_damage(999)
	t.equal(hero.hp, 0, "health clamped at zero")
	t.equal(hero.start_attack(), false, "dead fighter cannot attack")
	t.equal(hero.start_dash(), false, "dead fighter cannot dash")

func test_negative_time_cannot_rewind_combat(t) -> void:
	var hero = Fighter.new(Stats.new())
	hero.start_attack()
	hero.advance(-5)
	t.equal(hero.start_attack(), false, "negative time ignored")

func test_sword_only_damages_during_downward_cut(t) -> void:
	var hero = Fighter.new(Stats.new())
	var enemy = Fighter.new(Stats.new())
	hero.start_attack()
	t.equal(hero.strike(enemy, 25.0), false, "windup cannot damage")
	hero.advance(0.18)
	t.truth(hero.strike(enemy, 25.0), "extended blade damages in active phase")
	hero.advance(0.08)
	var late_target = Fighter.new(Stats.new())
	t.equal(hero.strike(late_target, 25.0), false, "recovery cannot damage new targets")

func test_turning_during_swing_cannot_move_damage_behind_hero(t) -> void:
	var hero = Fighter.new(Stats.new())
	hero.start_attack()
	hero.facing = -1
	hero.advance(0.18)
	t.equal(hero.strike(Fighter.new(Stats.new()), -25.0), false, "swing keeps its original direction")
	t.truth(hero.strike(Fighter.new(Stats.new()), 25.0), "blade and damage still face right")

func test_short_cooldown_cannot_restart_an_unfinished_swing(t) -> void:
	var stats = Stats.new()
	stats.attack_duration = 1.0
	stats.attack_cooldown = 0.1
	var hero = Fighter.new(stats)
	hero.start_attack()
	hero.advance(0.2)
	t.equal(hero.start_attack(), false, "cooldown ending cannot interrupt an unfinished sword animation")

func test_dash_cancels_damage_in_every_swing_phase(t) -> void:
	for elapsed in [0.05, 0.18, 0.30]:
		var hero = Fighter.new(Stats.new())
		hero.start_attack()
		hero.advance(elapsed)
		t.truth(hero.start_dash(), "dash can cancel the current swing")
		t.equal(hero.attack_progress(), 1.0, "cancelled swing reports complete to presentation")
		t.equal(hero.strike(Fighter.new(Stats.new()), 25.0), false, "cancelled swing cannot damage")

func test_overhead_anticipation_cannot_damage_before_downward_cut(t) -> void:
	var hero = Fighter.new(Stats.new())
	var enemy = Fighter.new(Stats.new())
	hero.start_attack()
	hero.advance(0.07)
	t.equal(hero.strike(enemy, 25.0), false, "raised sword is still anticipation")
	hero.advance(0.11)
	t.truth(hero.strike(enemy, 25.0), "downward cut makes contact")

func test_dash_progress_tracks_motion_until_it_finishes(t) -> void:
	var hero = Fighter.new(Stats.new())
	hero.start_dash()
	t.equal(hero.dash_progress(), 0.0, "launch begins at start of dash")
	hero.advance(0.1)
	t.truth(is_equal_approx(hero.dash_progress(), 0.5), "dash animation can follow midpoint of actual motion")
	hero.advance(0.2)
	t.equal(hero.dash_progress(), 1.0, "finished dash releases its pose")

func test_shield_absorbs_damage_before_health_and_cannot_regenerate(t) -> void:
	var hero = Fighter.new(Stats.new())
	hero.shield = 20
	t.truth(hero.take_damage(15), "shield contact counts as a confirmed hit")
	t.equal(hero.hp, 100, "shield protects health")
	t.equal(hero.shield, 5, "shield consumes only incoming damage")
	t.equal(hero.shield_absorbed, 15, "report tracks prevented health loss")
	t.equal(hero.take_damage(15), false, "hurt invulnerability prevents shield double drain")
	hero.advance(1.0)
	t.truth(hero.take_damage(15), "next hit consumes remaining shield")
	t.equal(hero.hp, 90, "overflow reaches health")
	t.equal(hero.shield, 0, "shield never goes negative")
	hero.advance(10.0)
	t.equal(hero.shield, 0, "crystal shield does not recharge with stamina")

func test_combo_accepts_early_press_without_restarting_the_current_swing(t) -> void:
	var stats = Stats.new()
	stats.combo_enabled = true
	var hero = Fighter.new(stats)
	hero.start_attack()
	hero.advance(0.12)
	var progress: float = hero.attack_progress()
	t.truth(hero.start_attack(), "second press is accepted into the combo buffer")
	t.equal(hero.attack_progress(), progress, "buffering cannot restart the current sword")
	hero.advance(0.20)
	t.truth(hero.attack_progress() < 0.2, "buffered return cut begins during first recovery")

func combo_fighter():
	var stats = Stats.new()
	stats.combo_enabled = true
	return Fighter.new(stats)

func test_combo_requires_three_presses_and_finisher_recovers(t) -> void:
	var hero = combo_fighter()
	hero.start_attack()
	hero.advance(0.1)
	hero.start_attack()
	hero.advance(0.22)
	t.equal(hero.combo_step, 2, "buffer reaches return cut")
	hero.start_attack()
	hero.start_attack() # Mashing can reserve only one continuation.
	hero.advance(0.24)
	t.equal(hero.combo_step, 3, "third press reaches heavy finisher")
	t.equal(hero.start_attack(), false, "finisher cannot queue a fourth slash")
	hero.advance(0.44)
	t.equal(hero.start_attack(), false, "finisher must recover before another chain")
	hero.advance(0.2)
	t.truth(hero.start_attack(), "new chain starts after recovery")
	t.equal(hero.combo_step, 1, "new chain begins with first cut")

func test_single_press_late_followup_and_expired_chain(t) -> void:
	var hero = combo_fighter()
	hero.start_attack()
	hero.advance(0.39)
	t.equal(hero.attack_remaining, 0.0, "one press does not auto-combo")
	t.truth(hero.start_attack(), "slightly late second press still connects")
	t.equal(hero.combo_step, 2, "late press is a return cut")
	hero.advance(1.0)
	hero.start_attack()
	t.equal(hero.combo_step, 1, "waiting resets the combo")

func test_combo_target_can_receive_each_cut_only_once(t) -> void:
	var hero = combo_fighter()
	var target_stats = Stats.new()
	target_stats.max_hp = 200
	target_stats.hurt_invulnerability = 0.12
	var target = Fighter.new(target_stats)
	var landed := 0
	var steps := {}
	for tick in range(90):
		hero.advance(1.0/60)
		target.advance(1.0/60)
		if tick in [0,8,23]: hero.start_attack()
		if hero.strike(target,25):
			landed += 1
			steps[hero.combo_step] = true
			t.equal(hero.strike(target,25), false, "repeated overlap cannot duplicate this cut")
	t.equal(landed, 3, "three separate cuts land on one surviving target")
	t.equal(steps.size(), 3, "damage belongs to distinct combo stages")
	t.equal(target.hp, 110, "two 25 damage cuts plus 40 damage finisher")

func test_combo_cancels_on_dash_hurt_death_and_lost_intent(t) -> void:
	for interruption in ["dash","hurt","death","pause"]:
		var hero = combo_fighter()
		hero.start_attack()
		hero.advance(0.1)
		hero.start_attack()
		match interruption:
			"dash": hero.start_dash()
			"hurt": hero.take_damage(1)
			"death": hero.take_damage(999)
			"pause": hero.clear_attack_buffer()
		hero.advance(0.25)
		t.truth(hero.combo_step != 2, interruption+" cannot release a stale return cut")
		if interruption != "pause":
			t.equal(hero.attack_remaining, 0.0, interruption+" cancels visible and damaging sword together")

func test_buffer_expiry_and_large_time_step_obey_the_same_handoff(t) -> void:
	var short_buffer = combo_fighter()
	short_buffer.stats.combo_buffer_seconds = 0.03
	short_buffer.start_attack()
	short_buffer.advance(0.02)
	short_buffer.start_attack()
	short_buffer.advance(0.4)
	t.equal(short_buffer.combo_step, 1, "expired input cannot fire at a later handoff")
	var coarse = combo_fighter()
	var fine = combo_fighter()
	for hero in [coarse,fine]:
		hero.start_attack()
		hero.advance(0.1)
		hero.start_attack()
	coarse.advance(0.25)
	for tick in range(25): fine.advance(0.01)
	t.equal(coarse.combo_step, fine.combo_step, "coarse and fine frames choose same combo stage")
	t.truth(is_equal_approx(coarse.attack_progress(),fine.attack_progress()), "handoff preserves leftover time")

func test_each_combo_cut_locks_direction_when_it_begins(t) -> void:
	var hero = combo_fighter()
	hero.start_attack()
	hero.advance(0.1)
	hero.facing = -1
	hero.start_attack()
	t.equal(hero.attack_facing, 1, "queued turn cannot flip current sword")
	hero.advance(0.22)
	t.equal(hero.attack_facing, -1, "new cut takes current movement facing")

func test_stationary_combo_never_displaces_the_knight(t) -> void:
	var hero = combo_fighter()
	for step in range(3):
		hero.start_attack()
		hero.advance(0.5 if step==2 else 0.34)
		t.equal(hero.consume_attack_travel(),0.0,"no direction keeps every slash planted")

func test_followup_travel_is_timed_directional_and_consumed_once(t) -> void:
	var hero = combo_fighter()
	hero.start_attack()
	hero.advance(0.34)
	t.equal(hero.consume_attack_travel(1), 22.0, "held direction advances the opening slash")
	hero.start_attack()
	hero.advance(0.04)
	t.equal(hero.consume_attack_travel(1), 0.0, "followup anticipation stays planted")
	hero.facing = -1
	hero.advance(0.09)
	var partial: float = hero.consume_attack_travel(1)
	t.truth(partial > 0.0 and partial < 22.0, "followup advances during the cut in its locked direction")
	t.equal(hero.consume_attack_travel(1), 0.0, "same movement cannot be applied twice")
	hero.advance(0.2)
	t.truth(is_equal_approx(partial + hero.consume_attack_travel(1), 22.0), "second cut travels its full distance")
	hero.start_attack()
	hero.advance(0.5)
	t.truth(is_equal_approx(hero.consume_attack_travel(-1), -32.0), "finisher steps farther in its own locked direction")

func test_step_distance_survives_coarse_handoff_and_custom_timing(t) -> void:
	for duration in [0.2, 0.6]:
		var coarse = combo_fighter()
		var fine = combo_fighter()
		for hero in [coarse, fine]:
			hero.stats.attack_duration = duration
			hero.start_attack()
			hero.advance(duration * 0.8)
			hero.consume_attack_travel()
			hero.start_attack()
		coarse.advance(duration * 1.2)
		var total := 0.0
		for tick in range(120):
			fine.advance(duration / 100.0)
			total += fine.consume_attack_travel(1)
		t.truth(is_equal_approx(coarse.consume_attack_travel(1), total) and is_equal_approx(total, 22.0), "frame size and swing duration do not change forward step distance")

func test_cancelled_combo_discards_unapplied_step(t) -> void:
	for cancel in ["dash", "hurt", "death"]:
		var hero = combo_fighter()
		hero.start_attack()
		hero.advance(0.34)
		hero.start_attack()
		hero.advance(0.13)
		if cancel == "dash": hero.start_dash()
		else: hero.take_damage(999 if cancel == "death" else 1)
		t.equal(hero.consume_attack_travel(1), 0.0, "cancel discards pending step: " + cancel)
		hero.advance(0.3)
		t.equal(hero.consume_attack_travel(1), 0.0, "cancelled sword cannot resume stepping: " + cancel)

func test_releasing_direction_discards_travel_without_a_backlog(t) -> void:
	var hero = combo_fighter()
	hero.start_attack();hero.advance(0.18)
	t.truth(hero.consume_attack_travel(1)>0,"direction begins an active forward step")
	hero.advance(0.04)
	t.equal(hero.consume_attack_travel(0),0.0,"releasing direction cancels current travel")
	t.equal(hero.consume_attack_travel(1),0.0,"pressing again cannot recover discarded travel")
	hero.advance(0.2)
	var rest: float=hero.consume_attack_travel(-1)
	t.truth(rest>0 and rest<22,"opposite input keeps only remaining travel in locked swing direction")
