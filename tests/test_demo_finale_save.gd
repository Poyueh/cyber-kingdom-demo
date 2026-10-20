extends RefCounted
## The Demo's rocket finale lives in the ordinary campaign record (there is no voyage
## envelope), so the dragon core and the rocket survive a save, and broken data is refused.
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Ops=preload("res://application/planet_operations.gd")
const BODY: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}

func demo_config() -> Dictionary:
	var tuning: Resource=load("res://data/campaign.tres")
	var base: Dictionary=tuning.campaign_rules()
	base.merge({"seed":1054,"economy":tuning.economy_rules()},true)
	var forest: Resource=load("res://data/planets/forest.tres")
	var setup: Script=load("res://application/journey_setup.gd")
	var config: Dictionary=setup.create_forest(base,forest.rules(),load("res://data/journey_paces.tres").find(0).rules())
	config.merge(setup.gate_rules(forest),true)
	return load("res://data/core_loop.tres").resolve_demo(config)

## A lit camp after the guided nights with the forest dragon down and no raiders left
## (trail creatures belong to their encounters and stay).
func after_dragon(config: Dictionary) -> RefCounted:
	var sim: RefCounted=Campaign.new(config)
	sim.interact(sim.world.sites.hall,"hall")
	sim.core_loop.income=6;sim.core_loop.stage=5;sim.core_loop.checkpoint_index=0;sim.core_loop.checkpoint_pending=0
	sim.clock.survived=2;sim.clock.day=3
	for rift: Dictionary in sim.mission.rifts:rift.sealed=true
	sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
	sim.raiders=sim.raiders.filter(func(enemy: Dictionary)->bool:return enemy.has("trail_slot"))
	sim.advance(1.0/30.0,sim.world.sites.hall)
	return sim

func round_trip(codec: RefCounted, packet: Dictionary) -> Dictionary:
	return codec.restore(JSON.parse_string(JSON.stringify(packet)))

func test_a_partly_funded_rocket_survives_a_save(t):
	var config: Dictionary=demo_config()
	var sim: RefCounted=after_dragon(config)
	t.truth(sim.interact(Ops.core_x(sim),"dragon_core"),"the core is claimed")
	sim.pouch.amount=sim.pouch.capacity
	var pad: float=Ops.rocket_x(sim)
	for i: int in range(15):sim.interact(pad,"rocket")
	var codec: RefCounted=Codec.new()
	var restored: Dictionary=round_trip(codec,codec.capture(sim,config,BODY))
	t.truth(not restored.is_empty(),"a demo record with 15 crystals in the rocket loads (%s)"%codec.last_error)
	if restored.is_empty():return
	t.truth(restored.session.planet.core_claimed,"the claimed core is kept")
	t.equal(restored.session.context(pad).paid,15,"the crystals already paid into the rocket are kept")

func test_older_records_gain_an_untouched_finale(t):
	var config: Dictionary=demo_config()
	var codec: RefCounted=Codec.new()
	var packet: Dictionary=codec.capture(after_dragon(config),config,BODY)
	packet.version=22;preload("res://tests/legacy_checkpoint.gd").before_planet(packet)
	var restored: Dictionary=round_trip(codec,packet)
	t.truth(not restored.is_empty(),"a version 22 demo record still loads (%s)"%codec.last_error)
	if restored.is_empty():return
	t.truth(restored.session.planet.cleared and not restored.session.planet.core_claimed,"its fallen dragon leaves a core to claim")
	t.equal(codec.capture(restored.session,restored.config,BODY).version,Codec.VERSION,"it resaves in the current format")

func test_broken_finale_data_is_refused(t):
	var config: Dictionary=demo_config()
	var codec: RefCounted=Codec.new()
	var base: Dictionary=codec.capture(after_dragon(config),config,BODY)
	t.truth(not round_trip(codec,base).is_empty(),"the control record loads")
	var cases: Dictionary={}
	var bad: Dictionary=base.duplicate(true);bad.erase("planet");cases["missing planet"]=bad
	bad=base.duplicate(true);bad.planet.core_claimed=true;bad.planet.cleared=false;cases["core without a fallen dragon"]=bad
	bad=base.duplicate(true);bad.mission.dragon_defeated=false;bad.mission.outcome="active";cases["cleared world with a living dragon"]=bad
	bad=base.duplicate(true);bad.planet.work=999.0;cases["impossible rocket work"]=bad
	var legacy: Dictionary=config.duplicate(true);legacy.erase("rocket_finale")
	bad=codec.capture(Campaign.new(legacy),legacy,BODY);bad.planet.cleared=true;bad.planet.core_claimed=true;bad.planet.reactor=true
	cases["a rocket in a world without one"]=bad
	for label: String in cases:
		t.truth(round_trip(codec,cases[label]).is_empty(),"refused: "+label)
