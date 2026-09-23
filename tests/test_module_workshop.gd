extends RefCounted
const Campaign = preload("res://application/campaign_session.gd")
const Codec = preload("res://application/campaign_snapshot.gd")
const Rules = preload("res://application/campaign_checkpoint_rules.gd")
const CONFIG: Dictionary = {"seed":42,"immersive_loop":1,"day_seconds":1000.0}

func fresh() -> RefCounted:
	var sim: RefCounted = Campaign.new(CONFIG)
	sim.world.people.clear()
	sim.interact(30,"hall")
	return sim

func test_new_relic_equips_immediately_and_replaces_the_previous_module(t: SceneTree) -> void:
	var sim: RefCounted = fresh()
	var money: int = sim.pouch.amount
	for relic: RefCounted in sim.modules.relics:
		sim.advance(0.1,relic.x)
		t.equal(sim.modules.equipped,relic.id,"new discovery equips on pickup")
		t.truth(sim.modules.stored.has(relic.id),"discovery remains available for later switching")
	t.equal(sim.pouch.amount,money,"first-time discoveries never charge crystals")
	sim.advance(0.1,sim.modules.relics[0].x)
	t.equal(sim.modules.equipped,"lance","returning to an empty relic site cannot equip again for free")

func test_workshop_charges_eight_only_for_valid_changes_and_cannot_upgrade_knight(t: SceneTree) -> void:
	var sim: RefCounted = fresh()
	var at: float = sim.world.sites.drill
	t.truth(not sim.equip_module("arc",at),"empty workshop cannot install unknown modules")
	t.truth(not sim.interact(at,"drill:0"),"knight training cannot be purchased")
	t.equal(sim.frontier.drill_level,0,"workshop never grants knight levels")
	for relic: RefCounted in sim.modules.relics:sim.advance(0.1,relic.x)
	sim.pouch.amount=7
	t.truth(not sim.equip_module("arc",at),"seven crystals are insufficient")
	t.equal(sim.pouch.amount,7,"failed switch has no partial charge")
	sim.pouch.amount=12
	t.truth(not sim.equip_module("arc",at+200),"paid switching requires the workshop")
	t.truth(not sim.equip_module("lance",at),"equipped module cannot be bought again")
	t.equal(sim.pouch.amount,12,"invalid switches preserve crystals")
	t.truth(sim.equip_module("arc",at),"eight crystals buy a switch to a discovered module")
	t.equal(sim.pouch.amount,4,"successful change costs exactly eight")
	t.equal(sim.modules.equipped,"arc","paid choice becomes active")
	t.equal(sim.frontier.drill_level,0,"switching does not upgrade the knight")

func test_cooldown_finishes_once_and_saved_run_keeps_the_same_timing(t: SceneTree) -> void:
	var sim: RefCounted = fresh()
	sim.advance(0.1,sim.modules.relics[0].x)
	t.truth(sim.activate_module(30),"picked-up module is usable immediately")
	for i: int in range(40):sim.advance(1.0/30,30)
	var codec: RefCounted=Codec.new()
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var loaded: Dictionary=codec.restore(codec.capture(sim,CONFIG,body))
	t.truth(not loaded.is_empty(),"cooldown and auto-equipped inventory can be saved")
	if loaded.is_empty():return
	for copy: RefCounted in [sim,loaded.session]:
		var flashes: int=0
		for i: int in range(200):
			copy.effects.clear()
			copy.advance(1.0/30,30)
			for effect: Dictionary in copy.effects:
				if effect.kind=="module_ready":flashes+=1
		t.equal(flashes,1,"cooldown emits exactly one ready cue")
	t.truth(Rules.same(codec.capture(sim,CONFIG,body),codec.capture(loaded.session,CONFIG,body)),"save continuation keeps identical cooldown results")
