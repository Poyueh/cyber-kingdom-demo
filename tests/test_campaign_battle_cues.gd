extends RefCounted
## Combat, the walls and the player's own spending must be audible, once each.
const Session=preload("res://application/campaign_session.gd")
const Cues=preload("res://presentation/campaign_audio_cues.gd")

func _primed(sim):
	var cues=Cues.new()
	cues.sample(sim,sim.world.sites.hall,false)
	return cues

func test_falling_raiders_and_the_dragon_are_told_apart(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	sim.raiders.append(sim._spawn_raider())
	var cues=_primed(sim)
	sim.raiders[0].fighter.hp=0
	sim.raiders=sim.raiders.filter(func(r):return r.fighter.is_alive())
	t.truth("enemy_death" in cues.sample(sim,at,false),"a raider going down is heard")
	t.equal(cues.sample(sim,at,false).count("enemy_death"),0,"an empty field keeps repeating nothing")
	var dragon=sim._spawn_raider()
	dragon.kind="dragon"
	dragon.fighter.stats.max_hp=400;dragon.fighter.hp=400
	sim.raiders.append(dragon)
	cues.sample(sim,at,false)
	dragon.fighter.hp=300
	t.truth("dragon_hurt" in cues.sample(sim,at,false),"wounding the dragon is its own roar")
	dragon.fighter.hp=0
	sim.raiders=sim.raiders.filter(func(r):return r.fighter.is_alive())
	var fallen: Array=cues.sample(sim,at,false)
	t.truth("dragon_death" in fallen,"the dragon falling is heard")
	t.truth(not ("enemy_death" in fallen),"the dragon does not also sound like a small raider")

func test_the_walls_are_heard_taking_giving_and_regaining_ground(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	var wall: Dictionary=sim.world.walls["wall"]
	wall.level=1;wall.hp=60
	var cues=_primed(sim)
	wall.hp=45
	t.truth("wall_hit" in cues.sample(sim,at,false),"a wall being struck is heard")
	t.equal(cues.sample(sim,at,false).count("wall_hit"),0,"a standing wall does not keep sounding")
	wall.hp=0
	var broken: Array=cues.sample(sim,at,false)
	t.truth("wall_break" in broken,"a wall collapsing is heard")
	t.truth(not ("wall_hit" in broken),"a collapse is not just another strike")
	wall.hp=60
	t.truth("wall_repair" in cues.sample(sim,at,false),"a repaired wall is heard coming back")

func test_spending_on_yourself_is_audible(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	sim.hero.hp=sim.hero.stats.max_hp-30
	var cues=_primed(sim)
	sim.hero.hp+=30
	t.truth("heal" in cues.sample(sim,at,false),"health returning is heard")
	t.equal(cues.sample(sim,at,false).count("heal"),0,"full health does not keep healing")
	sim.pouch.toss(at,430.0,1)
	t.truth("throw" in cues.sample(sim,at,false),"an offered crystal is heard leaving the hand")
	t.equal(cues.sample(sim,at,false).count("throw"),0,"a thrown crystal is only thrown once")

func test_a_restored_battle_states_none_of_its_history(t):
	var sim=Session.new()
	sim.world.walls["wall"].level=1
	sim.world.walls["wall"].hp=0
	sim.hero.hp=sim.hero.stats.max_hp
	var cues=Cues.new()
	t.equal(cues.sample(sim,sim.world.sites.hall,false),[],"a loaded ruin does not collapse again on open")

func test_opening_a_chest_is_not_mistaken_for_losing_crystals(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	sim.survival.enabled=true
	var cues=_primed(sim)
	sim.pouch.burst(5,at)
	var opened: Array=cues.sample(sim,at,false)
	t.truth(not ("crystal_drop" in opened),"crystals spilling from a chest are not a wound")
	sim.pouch.amount=10
	cues.sample(sim,at,false)
	sim.survival.hits+=1
	sim.pouch.amount-=3
	sim.pouch.burst(3,at)
	t.truth("crystal_drop" in cues.sample(sim,at,false),"a real hit still spills the pouch audibly")

func test_a_refund_is_not_also_a_wound(t):
	var sim=Session.new()
	sim.life.enabled=true
	sim.survival.enabled=true
	var at: float=sim.world.sites.hall
	sim.investments["hall"]=2
	var cues=_primed(sim)
	sim.cancel_investment("hall",at)
	var refunded: Array=cues.sample(sim,at,false)
	t.truth("slot_refund" in refunded,"the refund itself is heard")
	t.truth(not ("crystal_drop" in refunded),"handing crystals back is not the wound sound")

func test_a_thief_getting_away_is_not_a_kill(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	var thief=sim._spawn_raider()
	thief.x=at
	sim.raiders.append(thief)
	var cues=_primed(sim)
	thief.fighter.hp=0
	thief["escaped"]=true
	var fled: Array=cues.sample(sim,at,false)
	t.truth(not ("enemy_death" in fled),"a raider escaping with its loot has not been killed")
	var slain=sim._spawn_raider()
	slain.x=at
	sim.raiders.append(slain)
	cues.sample(sim,at,false)
	slain.fighter.hp=0
	t.truth("enemy_death" in cues.sample(sim,at,false),"a raider actually killed still falls audibly")
