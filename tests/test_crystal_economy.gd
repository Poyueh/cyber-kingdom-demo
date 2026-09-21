extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func buy(sim,x: float) -> void:
 var choice: Dictionary=sim.context(x)
 for i in range(choice.cost):sim.interact(x,choice.key)
func test_only_crystals_build_upgrade_and_heal(t):
 var sim=Campaign.new()
 sim.world.people.clear()
 buy(sim,30)
 t.truth(sim.context(30).enabled,"town can upgrade with no other materials")
 buy(sim,30)
 t.equal(sim.frontier.city_level,2,"crystal payment upgrades the actual settlement")
 sim.pouch.amount=12
 buy(sim,-350)
 t.truth(sim.frontier.farm_active,"crystals alone plant a persistent farm")
 sim.hero.hp=40
 buy(sim,-850)
 t.equal(sim.hero.hp,70,"healing spends crystal slots and restores health")
 buy(sim,350)
 t.equal(sim.hero.shield,20,"capacitor requires no scrap")
 buy(sim,1230)
 t.equal(sim.hero.stats.damage,30,"training requires no food")
 t.equal(sim.pouch.amount,3,"farm heal capacitor and lesson spend nine crystals")
 t.truth(sim.context_for_key(-700,"trade").id.is_empty(),"obsolete exchange is not interactable")
 for site in sim.world.sites.values():
  t.truth(sim.context(site).get("requirements",{}).is_empty(),"no material requirements remain")
func test_all_harvests_and_farming_only_supply_physical_crystals(t):
 var sim=Campaign.new({"day_seconds":10000.0})
 t.truth(sim.frontier.nodes.all(func(n):return n.crystals>0 and n.wood+n.food+n.stone+n.herbs+n.scrap==0),"each terrain resource yields only crystals")
 sim.world.people.clear()
 sim.frontier.city_level=1
 buy(sim,-350)
 sim.world.people.append({"x":-350.0,"role":"farmer","hurt":0.0,"cooldown":0.0,"region":-1})
 var wallet: int=sim.pouch.amount
 sim.advance(24,1230)
 t.equal(sim.frontier.food,0,"farming does not accumulate another currency")
 t.equal(sim.pouch.ground_total(),4,"two harvests leave four crystals at the farm")
 t.equal(sim.pouch.amount,wallet,"remote production never bypasses backpack collection")
func test_v2_materials_convert_once_without_changing_original(t):
 var sim=Campaign.new({"seed":42,"flat_frontier":0,"fortifications":0})
 var codec=Codec.new()
 var packet: Dictionary=codec.capture(sim,{"seed":42},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 packet.session.erase("barracks_level")
 for field in ["buildings","build_seconds","tower_damage","tower_range"]:packet.session.erase(field)
 packet.erase("modules");packet.erase("spirit");packet.erase("survival");packet.erase("travel");packet.version=2
 for key in ["dragon_summoned","dragon_defeated","dragon_day","dragon_rules"]:packet.mission.erase(key)
 packet.frontier.wood=8;packet.frontier.food=3;packet.frontier.stone=2;packet.frontier.herbs=1
 packet.world.scrap=4
 packet.nodes[0].wood=4
 var before=packet.duplicate(true)
 var restored: Dictionary=codec.restore(packet)
 t.truth(not restored.is_empty(),"known v2 record remains playable")
 if restored.is_empty():return
 var run=restored.session
 t.equal(run.pouch.ground_total(),18,"legacy stores become eighteen ground crystals")
 t.equal(run.pouch.amount,12,"migration respects full backpack")
 t.equal(run.frontier.wood+run.frontier.food+run.frontier.stone+run.frontier.herbs+run.world.scrap,0,"legacy materials are cleared")
 t.equal(run.frontier.nodes[0].crystals,packet.nodes[0].crystals+4,"undelivered cargo retains all value")
 t.equal(packet,before,"reading never mutates the original snapshot")
 var reopened: Dictionary=codec.restore(codec.capture(run,restored.config,restored.body))
 t.equal(reopened.session.pouch.ground_total(),18,"saving and reading cannot convert the same resources twice")

func test_real_v2_checkpoint_and_renewable_yields_survive_migration(t):
 var packet: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/campaign-v2.json"))
 var berries: Dictionary=packet.nodes.filter(func(n):return n.kind=="berries")[0]
 berries.collected=true;berries.delivered=true
 var original=packet.duplicate(true)
 var restored: Dictionary=Codec.new().restore(packet)
 t.truth(not restored.is_empty(),"real v2 tuning and partially paid town restore")
 if restored.is_empty():return
 var sim=restored.session
 t.equal(sim.pouch.ground_total(),22,"real v2 stored materials convert at the camp")
 t.equal(sim.investments.get("hall:1",0),2,"partial town payment survives migration")
 var plant=sim.frontier.nodes.filter(func(n):return n.kind=="berries")[0]
 sim.ecology.renew(2,sim.world.people)
 t.truth(not plant.collected and plant.crystals>0,"previously harvested plants retain a renewable crystal yield")
 t.equal(packet,original,"legacy record remains unchanged")
