extends RefCounted
const Fighter=preload("res://domain/combatant.gd")
const Stats=preload("res://domain/combat_stats.gd")
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func test_actions_require_energy_and_each_combo_swing_pays_once(t) -> void:
	var stats=Stats.new();stats.attack_cost=12;stats.jump_cost=18;stats.stamina_regen=0;stats.combo_enabled=true
	var hero=Fighter.new(stats)
	hero.stamina=25
	t.truth(hero.start_attack(),"first swing can pay")
	t.equal(hero.stamina,13.0,"first swing spends once")
	t.truth(hero.start_attack(),"next cut is buffered")
	t.equal(hero.stamina,13.0,"buffering does not prematurely pay")
	hero.advance(0.31)
	t.equal(hero.combo_step,2,"buffered cut starts when its window opens")
	t.equal(hero.stamina,1.0,"second cut spends its own energy")
	t.truth(not hero.start_attack(),"insufficient energy cannot queue third attack")
	hero.advance(1.0)
	t.truth(not hero.start_dash() and not hero.spend_stamina(stats.jump_cost),"empty energy blocks dash and jump")
	t.equal(hero.stamina,1.0,"failed skills never make stamina negative")
	stats.stamina_regen=25;hero.advance(1.0)
	t.truth(hero.spend_stamina(stats.jump_cost),"rest restores enough energy to jump")

func test_queued_swing_rechecks_budget_at_execution(t) -> void:
	var stats=Stats.new();stats.attack_cost=12;stats.combo_enabled=true;stats.stamina_regen=0
	var hero=Fighter.new(stats);hero.stamina=25
	hero.start_attack();hero.start_attack()
	hero.spend_stamina(10)
	hero.advance(0.31)
	t.equal(hero.combo_step,1,"a jump or other spend cannot fund an unaffordable queued cut")
	t.equal(hero.stamina,3.0,"cancelled followup does not overspend")

func test_legacy_save_migrates_with_current_action_costs(t) -> void:
	var codec=Codec.new();var sim=Campaign.new({"seed":42,"flat_frontier":0,"fortifications":0})
	var old=codec.capture(sim,{"seed":42},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
	old.session.erase("barracks_level")
	for field in ["buildings","build_seconds","tower_damage","tower_range"]:old.session.erase(field)
	old.erase("travel");old.version=1;old.hero.stats.erase("attack_cost");old.hero.stats.erase("jump_cost")
	for key in ["dragon_summoned","dragon_defeated","dragon_day","dragon_rules"]:old.mission.erase(key)
	var copy=old.duplicate(true)
	var restored=codec.restore(old)
	t.truth(not restored.is_empty(),"known v1 checkpoint upgrades")
	if not restored.is_empty():t.equal(restored.session.hero.stats.attack_cost,12.0,"old ongoing run gains the current attack cost")
	t.equal(old,copy,"migration does not mutate input checkpoint")
	old.version=99
	t.truth(codec.restore(old).is_empty(),"future version still protected")
