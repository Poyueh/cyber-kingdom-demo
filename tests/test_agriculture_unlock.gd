extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")

func test_farm_facility_only_produces_tools_when_player_fully_pays(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new({"seed":42,"immersive_loop":1,"day_seconds":1000.0})
 sim.world.people.clear()
 sim.interact(30,"hall")
 for i: int in range(5):sim.interact(30,"hall:1")
 var rack: float=sim.world.sites.farm_tools
 sim.world.people.append({"x":rack,"role":"citizen","hurt":0.0,"cooldown":0.0,"region":-1})
 for i: int in range(100):sim.advance(1.0/30,1000)
 t.equal(sim.world.tools.hoe,0,"standing residents do not manufacture free farm tools")
 t.equal(sim.world.people[0].role,"citizen","unpaid facility does not assign farmers")
 sim.world.people.clear()
 t.equal(sim.context(rack).id,"farm_tools","standing at the facility targets production")
 sim.interact(rack,"farm_tools")
 t.equal(sim.world.tools.hoe,0,"one crystal cannot manufacture a two-crystal tool")
 sim.interact(rack,"farm_tools")
 t.equal(sim.world.tools.hoe,1,"facility produces a tool without needing a resident")
 for i: int in range(4):sim.interact(rack,"farm_tools")
 t.equal(sim.world.tools.hoe,3,"facility rack stores at most three tools")
 var before: int=sim.pouch.amount
 t.truth(not sim.interact(rack,"farm_tools"),"full rack cannot be paid again")
 t.equal(sim.pouch.amount,before,"full rack preserves crystals")
func test_paid_farm_tools_are_claimed_after_normal_camp_upgrade(t) -> void:
 var sim: RefCounted=Campaign.new({"seed":42,"immersive_loop":1,"day_seconds":1000.0})
 sim.world.people.clear()
 sim.interact(30,"hall")
 for i: int in range(5):sim.interact(30,"hall:1")
 var rack: float=sim.world.sites.farm_tools
 var hold: RefCounted=preload("res://application/investment_hold.gd").new()
 hold.step(0.016,true,true,sim,rack)
 hold.step(0.016,false,true,sim,rack)
 hold.step(0.3,true,true,sim,rack)
 t.equal(sim.world.tools.hoe,1,"two real taps manufacture one hoe at unlocked rack")
 sim.world.people.append({"x":rack,"role":"citizen","hurt":0.0,"cooldown":0.0,"region":-1})
 sim.advance(0.1,1000)
 t.equal(sim.world.people[0].role,"farmer","new resident takes produced hoe automatically")
 t.equal(sim.world.tools.hoe,0,"claimed hoe leaves the rack")

func test_farms_and_hoes_wait_for_second_refuge_tier(t) -> void:
 var sim=Campaign.new({"seed":42,"immersive_loop":1})
 sim.interact(30,"hall")
 for key in ["farm","farm_tools","heal"]:
  t.truth(sim.context_for_key(sim.world.sites[key],key).id.is_empty(),"tier one hides unavailable "+key)
 sim.world.people.clear()
 sim.world.people.append({"role":"citizen","x":sim.world.sites.farm_tools,"hurt":0.0,"cooldown":0.0,"region":-1})
 sim.world.tools.hoe=1
 sim.advance(0.1,2000)
 t.equal(sim.world.people[0].role,"citizen","early legacy hoe cannot create a farmer before tier two")
 for i in range(5):sim.interact(30,"hall:1")
 t.equal(sim.frontier.city_level,2,"normal hall payment reaches tier two")
 t.truth(sim.built.get("farm_tools",false),"farm tool facility builds automatically on unlock")
 sim.advance(0.1,2000)
 t.equal(sim.world.people[0].role,"farmer","unlocked citizen autonomously takes a hoe")
 t.truth(sim.context_for_key(sim.world.sites.farm,"farm").enabled,"tier two can plant the home farm")

func test_random_farm_plots_unlock_without_rerolling_or_losing_save_state(t) -> void:
 var config: Dictionary={"seed":42,"immersive_loop":1}
 var sim=Campaign.new(config)
 sim.frontier.city_level=1
 var field: String=""
 for id in sim.buildings:
  if sim.buildings[id].kind=="farm":field=id;break
 t.truth(not field.is_empty(),"seed has an explorable farm plot")
 if field.is_empty():return
 var site: Dictionary=sim.buildings[field]
 sim.frontier.regions[site.region].discovered=true
 for node in sim.frontier.nodes:
  if absf(node.x-site.x)<90:node.collected=true
 t.truth(not sim.building_visible(field),"clearing does not bypass agriculture tier")
 sim.frontier.city_level=2
 var choice: Dictionary=sim.building_context(field)
 t.truth(sim.building_visible(field) and choice.enabled,"same cleared footprint becomes farmable at tier two")
 for i in range(choice.cost):sim.interact(choice.x,choice.key)
 t.truth(site.pending,"field still needs an engineer after payment")
 var codec=preload("res://application/campaign_snapshot.gd").new()
 var body: Dictionary={"x":site.x,"y":430.0,"vx":0.0,"vy":0.0}
 var restored: Dictionary=codec.restore(codec.capture(sim,config,body))
 t.truth(not restored.is_empty(),"unlock and queued construction can be resumed")
 if restored.is_empty():return
 for i in range(30):
  sim.advance(1.0/30,site.x);restored.session.advance(1.0/30,site.x)
 t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(codec.capture(sim,config,body),codec.capture(restored.session,config,body)),"farm progression matches uninterrupted play")
