extends RefCounted

const Campaign = preload("res://application/campaign_session.gd")
const Codec = preload("res://application/campaign_snapshot.gd")
const Rules = preload("res://application/campaign_checkpoint_rules.gd")
const CONFIG: Dictionary = {"seed":42,"immersive_loop":1,"crystal_survival":1,"hit_crystal_loss":3,"day_seconds":1000.0}

func fresh() -> RefCounted:
	var sim: RefCounted = Campaign.new(CONFIG)
	sim.interact(30, "hall")
	sim.world.people.clear()
	return sim

func enemy_at(sim: RefCounted, x: float, side: int) -> Dictionary:
	var enemy: Dictionary = sim._spawn_raider()
	enemy.x = x
	enemy.side = side
	enemy.wall_damage = 1
	sim.raiders.append(enemy)
	return enemy

func test_module_knockback_cannot_push_enemy_through_finished_wall(t: SceneTree) -> void:
	for side: int in [-1, 1]:
		var sim: RefCounted = fresh()
		var id: String = "wall" if side == 1 else "wall_left"
		var at: float = sim.world.sites[id]
		sim.world.walls[id].merge({"level":1,"hp":40}, true)
		var enemy: Dictionary = enemy_at(sim, at + side * 10, side)
		sim.modules.found.assign(["arc"])
		sim.modules.stored.assign(["arc"])
		sim.modules.equipped = "arc"
		t.truth(sim.activate_module(at + side * 50), "module activates outside the wall")
		t.truth(enemy.fighter.hp < enemy.fighter.stats.max_hp, "module actually hits")
		t.truth((enemy.x - at) * side > 0, "module knockback stays on original wall side")

func test_finisher_cannot_push_enemy_through_finished_wall(t: SceneTree) -> void:
	for side: int in [-1, 1]:
		var sim: RefCounted = fresh()
		var id: String = "wall" if side == 1 else "wall_left"
		var at: float = sim.world.sites[id]
		sim.world.walls[id].merge({"level":1,"hp":40}, true)
		var enemy: Dictionary = enemy_at(sim, at + side * 10, side)
		sim.hero.stats.combo_enabled = true
		sim.hero.facing = -side
		for step: int in range(3):
			sim.hero.start_attack()
			if step < 2: sim.hero.advance(sim.hero.attack_remaining)
		sim.hero.advance(sim.hero.attack_remaining * 0.5)
		t.equal(sim.hero.combo_step, 3, "real combo reaches heavy strike")
		sim.strike_from(at + side * 40, 430)
		t.truth(enemy.fighter.hp < enemy.fighter.stats.max_hp, "heavy strike actually hits")
		t.truth((enemy.x - at) * side > 0, "heavy knockback stays outside wall")

func test_crystal_carrier_attacks_wall_on_exit_then_leaves_after_breach(t: SceneTree) -> void:
	for side: int in [-1, 1]:
		var sim: RefCounted = fresh()
		var id: String = "wall" if side == 1 else "wall_left"
		var at: float = sim.world.sites[id]
		sim.world.walls[id].merge({"level":1,"hp":40}, true)
		var enemy: Dictionary = enemy_at(sim, at - side * 40, side)
		sim.pouch.drop(1, enemy.x)
		sim.pouch.drops[0].age = 1.0
		sim.advance(1.0/30, 30)
		t.equal(enemy.get("carried_crystals",0), 1, "raider picks up a real crystal inside the wall")
		for i: int in range(60): sim.advance(1.0/30, 30)
		t.truth((enemy.x - at) * side < 0, "carrier cannot cross intact wall toward portal")
		t.truth(sim.world.walls[id].hp < 40, "blocked carrier attacks obstruction instead of freezing")
		t.equal(enemy.carried_crystals, 1, "blocked carrier retains the crystal")
		sim.world.walls[id].hp = 0
		for i: int in range(45): sim.advance(1.0/30, 30)
		t.truth((enemy.x - at) * side > 0, "carrier exits once wall is broken")

func test_carrier_wall_block_survives_save_and_repeated_run(t: SceneTree) -> void:
	var sim: RefCounted = fresh()
	sim.world.wall.merge({"level":1,"hp":40}, true)
	var enemy: Dictionary = enemy_at(sim, sim.world.sites.wall - 50, 1)
	sim.pouch.drop(1, enemy.x)
	sim.pouch.drops[0].age = 1.0
	for i: int in range(8): sim.advance(1.0/30, 30)
	var codec: RefCounted = Codec.new()
	var body: Dictionary = {"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var saved: Dictionary = codec.capture(sim, CONFIG, body)
	var restored: Dictionary = codec.restore(saved)
	t.truth(not restored.is_empty(), "blocked carrier restores without format migration")
	if restored.is_empty(): return
	for i: int in range(60):
		sim.advance(1.0/30, 30)
		restored.session.advance(1.0/30, 30)
	t.truth(Rules.same(codec.capture(sim, CONFIG, body), codec.capture(restored.session, CONFIG, body)), "save continuation repeats wall targeting and crystal retention")

func test_ordinary_raiders_stop_at_nearest_finished_wall_on_both_sides(t: SceneTree) -> void:
	for side: int in [-1, 1]:
		for level: int in [1, 2, 3]:
			var sim: RefCounted = fresh()
			var id: String = "wall" if side == 1 else "wall_left"
			var at: float = sim.world.sites[id]
			sim.world.walls[id].merge({"level":level,"hp":sim.world.wall_max_hp(level)}, true)
			var enemy: Dictionary = enemy_at(sim, at + side * 60, side)
			for i: int in range(90): sim.advance(1.0/30, 30)
			t.truth((enemy.x - at) * side > 0, "ordinary attacker cannot cross a completed tier")
			t.truth(sim.world.walls[id].hp < sim.world.wall_max_hp(level), "attacker damages blocking wall")

func test_inactive_wall_allows_module_knockback_and_carrier_departure(t: SceneTree) -> void:
	for pending: bool in [false, true]:
		var sim: RefCounted = fresh()
		var at: float = sim.world.sites.wall
		sim.world.wall.merge({"level":1,"hp":40 if pending else 0,"pending":pending}, true)
		var enemy: Dictionary = enemy_at(sim, at + 10, 1)
		sim.modules.found.assign(["arc"])
		sim.modules.stored.assign(["arc"])
		sim.modules.equipped = "arc"
		sim.activate_module(at + 50)
		t.truth(enemy.x < at, "construction and destroyed walls do not block knockback")
		sim.pouch.drop(1, enemy.x)
		sim.pouch.drops[0].age = 1.0
		for i: int in range(60): sim.advance(1.0/30, 30)
		t.truth(enemy.x > at, "carrier can return through an inactive wall")
		t.equal(sim.world.wall.hp, 40 if pending else 0, "carrier never attacks inactive defenses")
