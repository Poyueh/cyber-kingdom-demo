extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const NAMES: Array[String]=["forest","desert","frost","swamp","volcanic","storm","void"]
func rules(id: int, enabled: bool=true) -> Dictionary:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.merge({"seed":416,"economy":tuning.economy_rules(),"voyage_enabled":1},true)
	config.merge(load("res://data/planets/"+NAMES[id]+".tres").rules(),true)
	if enabled:config.merge({"dragon_opening_version":1,"dragon_opening_multiplier":1.5,"dragon_opening_minimum":6.0},true)
	return config
func scene(id: int, enabled: bool=true) -> RefCounted:
	var sim: RefCounted=Campaign.new(rules(id,enabled))
	sim.world.people.clear();sim.survival.armed=true
	for rift: Dictionary in sim.mission.rifts:rift.sealed=true
	sim._summon_dragon(2000)
	return sim
func advance(sim: RefCounted, dragon: Dictionary, seconds: float) -> void:
	if sim.planet.id==0:preload("res://application/dragon_assault.gd").advance(sim,dragon,seconds,4500,430)
	else:preload("res://application/biome_dragon_assault.gd").advance(sim,dragon,seconds,4500,430)
func begin_volley(sim: RefCounted) -> Dictionary:
	var dragon: Dictionary=sim.raiders[0]
	dragon.x=2500.0;dragon.direction=1.0;dragon.cooldown=0.0;dragon.windup=0.1
	dragon.target={"kind":"hero","x":2700.0}
	return dragon
func sword_damage(sim: RefCounted, dragon: Dictionary) -> int:
	sim.hero.stats.damage=20;sim.hero.stamina=100
	sim.hero.attack_remaining=0;sim.hero.cooldown_remaining=0;sim.hero.combo_step=0
	sim.hero.facing=1;sim.hero.start_attack();sim.hero.advance(sim.hero.stats.attack_duration*0.5)
	var hp: int=dragon.fighter.hp
	sim.strike_from(dragon.x-80,430);sim.strike_from(dragon.x-80,430)
	return hp-dragon.fighter.hp
func test_all_seven_dragons_reward_the_completed_volley_window(t: SceneTree) -> void:
	for id: int in range(7):
		var sim: RefCounted=scene(id);var dragon: Dictionary=begin_volley(sim)
		t.equal(sword_damage(sim,dragon),20,"attacking during a warning keeps ordinary damage")
		var beats: int=1 if id==0 else sim.planet.attack.beats
		for beat: int in range(beats):
			advance(sim,dragon,dragon.windup+0.01)
			if beat<beats-1:t.equal(sword_damage(sim,dragon),20,"a follow-up is still dangerous, not an opening")
		t.equal(sword_damage(sim,dragon),30,"one actual sword hit exploits the exposed core in "+NAMES[id])
		t.truth(dragon.cooldown>=6.0,"every completed volley leaves at least six seconds to counterattack")
		t.equal(sim.effects.filter(func(e: Dictionary)->bool:return e.kind=="dragon_opening").size(),1,"whole volley opens the core once")
		advance(sim,dragon,dragon.cooldown)
		t.equal(sword_damage(sim,dragon),20,"the damage opportunity closes before the next attack")
func test_arrival_and_legacy_dragons_do_not_gain_false_openings(t: SceneTree) -> void:
	var arrival: RefCounted=scene(0)
	t.equal(sword_damage(arrival,arrival.raiders[0]),20,"initial entrance delay is not exposed core")
	for id: int in range(7):
		var sim: RefCounted=scene(id,false);var dragon: Dictionary=begin_volley(sim)
		for beat: int in range(1 if id==0 else sim.planet.attack.beats):advance(sim,dragon,dragon.windup+0.01)
		t.equal(sword_damage(sim,dragon),20,"old journey damage remains unchanged")
		t.equal(sim.effects.filter(func(e: Dictionary)->bool:return e.kind=="dragon_opening").size(),0,"old journey keeps the old visual rule")

func opened(id: int=0) -> RefCounted:
	var sim: RefCounted=scene(id);var dragon: Dictionary=begin_volley(sim)
	for beat: int in range(1 if id==0 else sim.planet.attack.beats):advance(sim,dragon,dragon.windup+0.01)
	return sim
func test_modules_and_archers_share_the_visible_opening(t: SceneTree) -> void:
	var sim: RefCounted=opened(2);var dragon: Dictionary=sim.raiders[0]
	sim.modules.found.append("lance");sim.modules.stored.append("lance");sim.modules.equipped="lance"
	sim.hero.facing=1;sim.hero.stamina=100
	var hp: int=dragon.fighter.hp
	t.truth(sim.activate_module(dragon.x-100),"equipped exploration weapon fires into the exposed core")
	t.equal(hp-dragon.fighter.hp,roundi(sim.modules.spec_for("lance").damage*1.5),"special weapon receives one opening bonus")
	t.truth(sim.modules.ready_tick>0,"exploiting an opening still spends the real shared cooldown")
	var archer: Dictionary={"role":"hunter","x":dragon.x-140,"hurt":0.0,"cooldown":0.0,"region":-1,"module_command_until":roundi(sim.workforce.elapsed*30)+120}
	sim.world.people.append(archer);hp=dragon.fighter.hp
	t.truth(sim._shoot_nearest_raider(archer,220,20,0.8),"an archer can join the counterattack")
	t.equal(hp-dragon.fighter.hp,42,"command adds eight before exposed-core multiplier")
	t.truth(not archer.has("module_command_until"),"command is still consumed by one arrow")
	archer.cooldown=0;hp=dragon.fighter.hp
	sim._shoot_nearest_raider(archer,220,20,0.8)
	t.equal(hp-dragon.fighter.hp,30,"subsequent arrows do not duplicate the command bonus")
func test_towers_and_ordinary_enemies_keep_their_own_rules(t: SceneTree) -> void:
	var sim: RefCounted=opened(1);var dragon: Dictionary=sim.raiders[0]
	var tower: Dictionary=sim.buildings.beacon;tower.level=1;tower.pending=false;tower.cooldown=0
	dragon.x=tower.x+100
	var hp: int=dragon.fighter.hp;sim._advance_towers(0.02)
	t.equal(hp-dragon.fighter.hp,roundi(sim.tower_damage*1.5),"completed tower fire exploits the same opening")
	tower.pending=true;tower.cooldown=0;hp=dragon.fighter.hp;sim._advance_towers(0.02)
	t.equal(dragon.fighter.hp,hp,"an upgrading tower remains inactive even during an opening")
	var normal: Dictionary=sim._spawn_raider();normal.x=dragon.x;normal.target={"kind":"hero","x":2000.0};normal.cooldown=6.0
	t.equal(sim.attack_damage_against(normal,20),20,"ordinary enemy cooldown is never a dragon weakness")
func test_partial_attack_and_opening_continue_identically_after_reload(t: SceneTree) -> void:
	var Codec=preload("res://application/campaign_snapshot.gd")
	var Rules=preload("res://application/campaign_checkpoint_rules.gd")
	for id: int in range(7):
		for in_opening: bool in [false,true]:
			var sim: RefCounted=opened(id) if in_opening else scene(id)
			if not in_opening:begin_volley(sim)
			var body: Dictionary={"x":4500.0,"y":430.0,"vx":0.0,"vy":0.0}
			var codec: RefCounted=Codec.new();var saved: Dictionary=codec.capture(sim,rules(id),body)
			var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
			t.truth(not restored.is_empty(),"mid-fight checkpoint loads in "+NAMES[id])
			if restored.is_empty():continue
			t.equal(restored.session.attack_damage_against(restored.session.raiders[0],20),30 if in_opening else 20,"loaded cue and damage phase agree immediately")
			for tick: int in range(60):sim.advance(1.0/30,4500);restored.session.advance(1.0/30,4500)
			t.truth(Rules.same(codec.capture(sim,rules(id),body),codec.capture(restored.session,restored.config,body)),"sixty-tick continuation preserves timing and damage policy")
func test_opening_configuration_cannot_be_silently_corrupted(t: SceneTree) -> void:
	var Rules=preload("res://application/campaign_checkpoint_rules.gd")
	for invalid: Variant in [0,2,1.5,"1",null]:
		var bad: Dictionary=rules(0);bad.dragon_opening_version=invalid
		t.truth(not Rules.config_valid(bad),"unknown opening version is refused")
	for key: String in ["dragon_opening_version","dragon_opening_multiplier","dragon_opening_minimum"]:
		var bad: Dictionary=rules(0);bad.erase(key)
		t.truth(not Rules.config_valid(bad),"partial opening configuration is refused")
	for invalid: Variant in [0,3,INF,"power"]:
		var bad: Dictionary=rules(0);bad.dragon_opening_multiplier=invalid
		t.truth(not Rules.config_valid(bad),"invalid damage bonus is refused")
	var Voyage=preload("res://application/star_voyage.gd")
	var trip: RefCounted=Voyage.new(rules(0))
	var sim: RefCounted=Campaign.new(trip.configs[0])
	var saved: Dictionary=trip.capture(sim,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
	t.truth(not Voyage.restore(saved).is_empty(),"one consistent seven-world journey accepts the new rule")
	for key: String in ["dragon_opening_version","dragon_opening_multiplier","dragon_opening_minimum"]:saved.configs[2].erase(key)
	t.truth(Voyage.restore(saved).is_empty(),"a future planet cannot silently switch to a different opening rule")
