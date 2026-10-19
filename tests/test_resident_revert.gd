extends RefCounted
## A resident knocked back to wanderer stays near where they were hit; they never walk
## back to the wild spot where the knight first found them.
const Campaign=preload("res://application/campaign_session.gd")
const STEP: float=1.0/30.0

func guided() -> RefCounted:
	var tuning: Resource=load("res://data/campaign.tres")
	var base: Dictionary=tuning.campaign_rules()
	base.merge({"seed":1054,"economy":tuning.economy_rules()},true)
	var forest: Resource=load("res://data/planets/forest.tres")
	var setup: Script=load("res://application/journey_setup.gd")
	var config: Dictionary=setup.create_forest(base,forest.rules(),load("res://data/journey_paces.tres").find(0).rules())
	config.merge(setup.gate_rules(forest),true)
	return Campaign.new(load("res://data/core_loop.tres").resolve_demo(config))

func advance(sim: RefCounted, seconds: float, hero_x: float) -> void:
	for i in range(roundi(seconds/STEP)):sim.advance(STEP,hero_x)

func farthest_wanderer(sim: RefCounted) -> int:
	var best: int=-1
	for i in range(sim.world.people.size()):
		var person: Dictionary=sim.world.people[i]
		if person.role!="wanderer":continue
		if best<0 or absf(person.x-sim.world.sites.hall)>absf(sim.world.people[best].x-sim.world.sites.hall):best=i
	return best

func test_a_hit_archer_stays_where_they_fell(t):
	var sim: RefCounted=guided()
	var hall: float=sim.world.sites.hall
	var away: float=hall-600.0 # The knight stands clear of everyone involved.
	var index: int=farthest_wanderer(sim)
	t.truth(index>=0,"a wanderer waits in the wild")
	if index<0:return
	advance(sim,1.0,away) # Roaming anchors them to their wild spot.
	var person: Dictionary=sim.world.people[index]
	var wild: float=person.x
	person.role="hunter";person.x=sim.world.sites.wall
	advance(sim,2.0,away)
	var fell: float=person.x
	t.truth(absf(fell-wild)>300,"the archer now stands far from where they were found")
	t.truth(sim.world.hit_person(index),"an unshielded hit knocks the archer back to wanderer")
	advance(sim,20.0,away)
	t.equal(person.role,"wanderer","the archer is a wanderer again")
	t.truth(absf(person.x-fell)<=100,"they linger near where they fell (%.0f from it, wild spot %.0f away)"%[absf(person.x-fell),absf(person.x-wild)])
