extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")
const BODY: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}

func rules() -> Dictionary:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.merge({"seed":103,"economy":tuning.economy_rules()},true)
	config.merge(load("res://data/planets/forest.tres").rules(),true)
	return config

func settled(config: Dictionary) -> RefCounted:
	var sim: RefCounted=Campaign.new(config)
	sim.frontier.city_level=1;sim.survival.armed=true;sim.world.people.clear()
	for id: String in ["wall","wall_left"]:
		sim.world.walls[id].level=1;sim.world.walls[id].hp=40
	return sim

func test_far_gate_approach_reaches_defenses_within_the_first_minute(t: SceneTree) -> void:
	var sim: RefCounted=settled(rules())
	sim.clock.remaining=0.01
	var contact: float=-1.0
	for tick: int in range(600):
		sim.advance(0.1,30.0)
		for enemy: Dictionary in sim.raiders:
			var wall_x: float=sim.world.sites.wall_left if enemy.side<0 else sim.world.sites.wall
			if (enemy.x-wall_x)*enemy.side<=320.0:contact=(tick+1)*0.1
		if contact>=0:break
	t.truth(contact>=30.0 and contact<=60.0,"a remote first-night force reaches the defense after a fair approach, without a ninety-second empty night")

func test_march_keeps_close_combat_and_resident_escape_speed(t: SceneTree) -> void:
	var sim: RefCounted=settled(rules())
	var enemy: Dictionary=sim._spawn_raider();enemy.x=5000.0
	t.truth(sim.raider_speed(enemy)>140.0,"an ordinary raider crosses empty distant terrain faster")
	sim.world.people.append({"x":5500.0,"role":"engineer","hurt":0.0,"cooldown":0.0})
	t.equal(sim.raider_speed(enemy),70.0,"a worker in the field gets the original combat movement speed")
	sim.world.people.clear();enemy.x=sim.world.sites.hall+500.0
	t.equal(sim.raider_speed(enemy),70.0,"approaching the settlement has unchanged combat speed")

func test_paid_off_raider_leaves_remote_ground_without_a_long_night_tail(t: SceneTree) -> void:
	var sim: RefCounted=settled(rules())
	var enemy: Dictionary=sim._spawn_raider()
	enemy.x=sim.mission.entry_x(1)-2100.0;enemy.side=1;enemy.carried_crystals=1;enemy.retreat_x=sim.mission.entry_x(1)
	sim.raiders.append(enemy)
	var crystals: int=sim.pouch.amount
	for tick: int in range(300):sim.advance(1.0/30.0,30.0)
	t.truth(sim.raiders.is_empty(),"a bribed raider completes its remote return in ten seconds")
	t.equal(sim.pouch.amount,crystals,"a departure grants no bonus loot or crystal refund")

func test_near_knight_walls_and_towers_keep_the_same_movement(t: SceneTree) -> void:
	var sim: RefCounted=settled(rules())
	var enemy: Dictionary=sim._spawn_raider();enemy.x=5000.0;enemy.side=1
	sim.raiders.append(enemy)
	sim.advance(0.1,5600.0)
	t.truth(absf(enemy.x-4993.0)<0.001,"an actual approach within a knight's field view advances only the normal seven units")
	sim.advance(0.1,30.0)
	sim.world.add_wall("test_front",4800.0)
	sim.world.walls.test_front.level=1;sim.world.walls.test_front.hp=40
	t.equal(sim.raider_speed(enemy),70.0,"an expanded completed wall slows the approach outside combat range")
	sim.world.walls.test_front.hp=0;sim.world.walls.test_front.pending=true
	t.equal(sim.raider_speed(enemy),70.0,"a paid construction area also preserves reaction time")
	sim.world.walls.test_front.pending=false
	var tower: Dictionary=sim.buildings.beacon
	tower.x=4800.0;tower.level=3
	t.equal(sim.raider_speed(enemy),70.0,"a remote laser tower receives attackers at original speed")
	tower.level=0;tower.pending=true
	t.equal(sim.raider_speed(enemy),70.0,"a tower under construction gets a normal approach without gaining attack power")
	tower.pending=false
	t.truth(sim.raider_speed(enemy)>140.0,"an unbuilt blueprint alone does not stall the whole invasion")

func test_march_blends_smoothly_and_never_speeds_up_special_enemies(t: SceneTree) -> void:
	var sim: RefCounted=settled(rules());sim.world.walls.clear()
	var enemy: Dictionary=sim._spawn_raider()
	var speeds: Array[float]=[]
	for distance: float in [999.0,1000.0,1001.0,1250.0,1500.0,1501.0]:
		enemy.x=sim.world.sites.hall+distance;speeds.append(sim.raider_speed(enemy))
	t.truth(speeds[0]==70.0 and speeds[1]==70.0 and speeds[2]-speeds[1]<1.0,"combat boundary has no abrupt speed jump")
	t.truth(speeds[2]<speeds[3] and speeds[3]<speeds[4] and speeds[4]==speeds[5],"approach eases continuously between travel and combat speeds")
	enemy.x=6000.0;enemy.kind="warden"
	t.equal(sim.raider_speed(enemy),70.0,"guardians keep their existing approach")
	enemy.kind="dragon"
	t.equal(sim.raider_speed(enemy,100.0),100.0,"dragon movement rules are unchanged")

func test_legacy_retreat_and_march_rules_remain_exact(t: SceneTree) -> void:
	var config: Dictionary=rules()
	for key: String in config.keys():
		if key.begins_with("march_"):config.erase(key)
	var sim: RefCounted=settled(config)
	var enemy: Dictionary=sim._spawn_raider()
	enemy.x=5000.0;enemy.side=1;enemy.carried_crystals=1;enemy.retreat_x=sim.mission.entry_x(1);enemy.module_chill_until=120
	sim.raiders.append(enemy)
	sim.advance(0.1,30.0)
	t.truth(absf(enemy.x-5010.5)<0.001,"old saved crystal carriers retain their original 105-unit return speed")
	enemy.erase("module_chill_until")
	t.equal(sim.raider_speed(enemy),70.0,"old distant invasions keep their original walk speed")
	var loaded: Dictionary=Codec.new().restore(JSON.parse_string(JSON.stringify(Codec.new().capture(sim,config,BODY))))
	t.truth(not loaded.is_empty(),"legacy pace still restores without adding a march profile")
	if not loaded.is_empty():t.truth(not loaded.config.has("march_version"),"loading does not silently change a previous journey")

func test_new_retreat_respects_chill_and_completed_walls(t: SceneTree) -> void:
	var sim: RefCounted=settled(rules())
	var enemy: Dictionary=sim._spawn_raider();enemy.x=5000.0;enemy.side=1;enemy.module_chill_until=120
	var march_speed: float=sim.raider_speed(enemy)
	enemy.erase("module_chill_until")
	t.truth(march_speed<sim.raider_speed(enemy),"cold needle still reduces the remote approach")
	enemy.carried_crystals=1;enemy.retreat_x=sim.mission.entry_x(1)
	sim.raiders.append(enemy)
	sim.world.add_wall("test_return",5100.0)
	sim.world.walls.test_return.level=1;sim.world.walls.test_return.hp=40
	for tick: int in range(20):sim.advance(0.05,30.0)
	t.truth(enemy.x<5100.0 and sim.world.walls.test_return.hp>0,"carrying a crystal cannot phase through an intact return-path wall")
	t.equal(enemy.carried_crystals,1,"blocked retreat retains exactly one carried crystal")

func test_save_resume_during_march_matches_uninterrupted_invasion(t: SceneTree) -> void:
	var config: Dictionary=rules();var sim: RefCounted=settled(config)
	sim.clock.remaining=0.01
	for tick: int in range(450):sim.advance(1.0/30.0,30.0)
	var codec: RefCounted=Codec.new();var saved: Dictionary=codec.capture(sim,config,BODY)
	var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
	t.truth(not loaded.is_empty(),"a real force midway between gate and city is resumable")
	if loaded.is_empty():return
	for tick: int in range(450):
		sim.advance(1.0/30.0,30.0);loaded.session.advance(1.0/30.0,30.0)
	t.truth(Rules.same(codec.capture(sim,config,BODY),codec.capture(loaded.session,loaded.config,BODY)),"saved-and-resumed march has exactly the same positions, clocks, loot and progress")
	t.equal(codec.capture(loaded.session,loaded.config,BODY).version,Codec.VERSION,"resumed march resaves in the current checkpoint format")

func test_partial_or_unknown_march_profiles_are_rejected(t: SceneTree) -> void:
	var config: Dictionary=rules();var sim: RefCounted=settled(config)
	var codec: RefCounted=Codec.new();var saved: Dictionary=codec.capture(sim,config,BODY)
	for key: String in ["march_version","march_multiplier","march_caution_radius","march_blend_distance"]:
		var partial: Dictionary=saved.duplicate(true);partial.config.erase(key)
		t.truth(codec.restore(partial).is_empty(),"missing march profile member is rejected: "+key)
	for alteration: Dictionary in [{"march_version":2},{"march_multiplier":NAN},{"march_multiplier":0.0},{"march_caution_radius":100.0},{"march_blend_distance":0.0}]:
		var corrupt: Dictionary=saved.duplicate(true);corrupt.config.merge(alteration,true)
		t.truth(codec.restore(corrupt).is_empty(),"unsupported or unsafe movement profile cannot overwrite a saved journey")
