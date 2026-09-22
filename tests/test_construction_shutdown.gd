extends RefCounted

const Campaign = preload("res://application/campaign_session.gd")
const Codec = preload("res://application/campaign_snapshot.gd")
const Rules = preload("res://application/campaign_checkpoint_rules.gd")
const CONFIG: Dictionary = {"seed":42, "immersive_loop":1, "day_seconds":1000.0}

func fresh() -> RefCounted:
	var sim: RefCounted = Campaign.new(CONFIG)
	sim.frontier.city_level = 3
	sim.world.people.clear()
	return sim

func pay(sim: RefCounted, x: float) -> void:
	sim.pouch.amount = 12
	var choice: Dictionary = sim.context(x)
	for i: int in range(choice.cost): sim.interact(x, choice.key)

func test_upgrading_tower_stops_shooting_until_engineer_finishes(t: SceneTree) -> void:
	var sim: RefCounted = fresh()
	sim.buildings.beacon.level = 1
	pay(sim, sim.world.sites.beacon)
	var enemy: Dictionary = sim._spawn_raider()
	enemy.x = sim.world.sites.beacon + 320
	enemy.fighter.stats.max_hp = 1000
	enemy.fighter.hp = 1000
	sim.raiders.append(enemy)
	for i: int in range(10): sim.advance(1.0/30, 30)
	t.equal(enemy.fighter.hp, 1000, "upgrading tower cannot hurt approaching enemies")
	t.truth(not sim.effects.any(func(e: Dictionary) -> bool: return e.kind in ["tower_arrow", "tower_laser"]), "construction emits no shots")
	sim.raiders.clear()
	sim.world.people.append({"role":"engineer", "x":sim.world.sites.beacon, "y":430.0, "hurt":0.0, "cooldown":0.0, "region":-1})
	for i: int in range(100): sim.advance(1.0/30, 30)
	t.equal(sim.buildings.beacon.level, 2, "engineer completes the upgrade")
	enemy.x = sim.world.sites.beacon + 320
	sim.raiders.append(enemy)
	sim.advance(1.0/30, 30)
	t.truth(enemy.fighter.hp < 1000, "completed tower resumes shooting")

func test_paid_wall_upgrade_opens_route_and_completion_closes_it(t: SceneTree) -> void:
	for pending: bool in [false, true]:
		var sim: RefCounted = fresh()
		sim.world.wall.merge({"level":1, "hp":40}, true)
		if pending: pay(sim, sim.world.sites.wall)
		else: sim.interact(sim.world.sites.wall, sim.context(sim.world.sites.wall).key)
		var enemy: Dictionary = sim._spawn_raider()
		enemy.x = sim.world.sites.wall + 20
		enemy.wall_damage = 1
		sim.raiders.append(enemy)
		for i: int in range(45): sim.advance(1.0/30, 30)
		t.equal(enemy.x < sim.world.sites.wall-40, pending, "fully paid construction lets invaders cross; partial funding keeps the wall active")
		if not pending: continue
		sim.raiders.clear()
		sim.world.people.append({"role":"engineer", "x":sim.world.sites.wall-12, "y":430.0, "hurt":0.0, "cooldown":0.0, "region":-1})
		for i: int in range(100): sim.advance(1.0/30, 30)
		t.equal(sim.world.wall.level, 2, "wall upgrade finishes normally")
		enemy.x = sim.world.sites.wall + 20
		enemy.windup = 0.0
		sim.raiders.append(enemy)
		for i: int in range(45): sim.advance(1.0/30, 30)
		t.truth(enemy.x >= sim.world.sites.wall, "completed wall blocks again")

func test_saved_upgrades_stay_inactive_and_continue_identically(t: SceneTree) -> void:
	var sim: RefCounted = fresh()
	sim.buildings.beacon.level = 2
	sim.world.wall.merge({"level":1, "hp":40}, true)
	pay(sim, sim.world.sites.beacon)
	pay(sim, sim.world.sites.wall)
	var codec: RefCounted = Codec.new()
	var body: Dictionary = {"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var loaded: Dictionary = codec.restore(codec.capture(sim, CONFIG, body))
	t.truth(not loaded.is_empty(), "partially constructed defenses restore")
	if loaded.is_empty(): return
	for copy: RefCounted in [sim, loaded.session]:
		var enemy: Dictionary = copy._spawn_raider()
		enemy.x = copy.world.sites.wall + 20
		copy.raiders.append(enemy)
		for i: int in range(45): copy.advance(1.0/30, 30)
		t.truth(enemy.x < copy.world.sites.wall-40, "restored construction offers no wall protection")
		t.equal(enemy.fighter.hp, enemy.fighter.stats.max_hp, "restored upgrading laser tower is silent")
	t.truth(Rules.same(codec.capture(sim, CONFIG, body), codec.capture(loaded.session, CONFIG, body)), "save continuation matches uninterrupted construction")

func test_wall_repair_cancels_an_attack_already_winding_up(t: SceneTree) -> void:
	var sim: RefCounted = fresh()
	sim.world.wall.merge({"level":1, "hp":30}, true)
	var enemy: Dictionary = sim._spawn_raider()
	enemy.x = sim.world.sites.wall+20
	sim.raiders.append(enemy)
	sim.advance(1.0/30, 30)
	t.truth(enemy.windup > 0, "enemy has started attacking the damaged wall")
	pay(sim, sim.world.sites.wall)
	for i: int in range(20): sim.advance(1.0/30, 30)
	t.truth(enemy.x < sim.world.sites.wall, "enemy abandons the old wall attack and walks through repairs")
	t.equal(sim.world.wall.hp, 30, "stale attack cannot hit an offline wall")
