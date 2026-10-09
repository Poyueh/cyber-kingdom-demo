extends RefCounted
const Voyage=preload("res://application/star_voyage.gd")
const Campaign=preload("res://application/campaign_session.gd")
const Progress=preload("res://application/campaign_progress.gd")
const Memory=preload("res://application/ports/campaign_store.gd")
const BODY={"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}
func config() -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var result: Dictionary=tuning.campaign_rules()
 result.merge({"seed":21841,"economy":tuning.economy_rules()},true)
 return result
func cleared(sim: RefCounted) -> void:
 for rift: Dictionary in sim.mission.rifts:rift.sealed=true
 sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
 sim.frontier.city_level=1;sim.survival.armed=true
 sim.advance(0.1,30)
func test_three_world_trip_retains_colony_and_requires_rebuilding(t: SceneTree) -> void:
 var voyage: RefCounted=Voyage.new(config())
 var sim: RefCounted=Campaign.new(voyage.configs[0])
 t.truth(voyage.prepare(sim,BODY,1).is_empty(),"cannot travel before a dragon core and rocket")
 cleared(sim)
 t.truth(sim.is_running(),"first dragon victory leaves the colony playable")
 t.truth(sim.planet.claim_core(),"dragon core can be claimed once")
 t.truth(not sim.planet.claim_core(),"core cannot be duplicated")
 sim.planet.rocket_ready=true
 sim.pouch.amount=13
 sim.frontier.nodes[0].collected=true;sim.frontier.nodes[0].delivered=true
 var trip: Dictionary=voyage.prepare(sim,BODY,1)
 t.truth(not trip.is_empty(),"built rocket enables second planet")
 if trip.is_empty():return
 t.equal(trip.session.pouch.amount,13,"crystals travel without refill")
 t.truth(trip.session.survival.armed,"knight brings the sword")
 t.equal(trip.session.frontier.city_level,0,"new world begins as wilderness")
 t.truth(trip.session.planet.wrecked and not trip.session.planet.rocket_ready,"landing destroys the rocket")
 t.truth(trip.journey.prepare(trip.session,BODY,0).is_empty(),"must rebuild wreck to revisit")
 trip.session.planet.rocket_ready=true
 var back: Dictionary=trip.journey.prepare(trip.session,BODY,0)
 t.truth(not back.is_empty(),"repaired wreck can return to old colony")
 if back.is_empty():return
 t.truth(back.session.frontier.nodes[0].collected,"harvested resources stay harvested")
 t.equal(back.session.frontier.city_level,1,"old town remains built")
 t.truth(back.session.planet.core_claimed,"old dragon core cannot respawn")
 t.truth(back.session.planet.wrecked and not back.session.planet.rocket_ready,"each landing leaves a wreck")
func test_voyage_save_rejects_corrupt_inactive_planets(t: SceneTree) -> void:
 var voyage: RefCounted=Voyage.new(config())
 var sim: RefCounted=Campaign.new(voyage.configs[0])
 cleared(sim);sim.planet.claim_core();sim.planet.rocket_ready=true
 var trip: Dictionary=voyage.prepare(sim,BODY,2)
 t.truth(not trip.is_empty(),"third world can be chosen after forest")
 if trip.is_empty():return
 var packet: Dictionary=trip.journey.capture(trip.session,trip.body)
 var restored: Dictionary=Voyage.restore(packet)
 t.truth(not restored.is_empty(),"whole voyage round trips")
 t.equal(restored.session.map_seed,trip.session.map_seed,"active map seed survives")
 packet.planets[0].campaign.nodes[0].crystals=-999
 t.truth(Voyage.restore(packet).is_empty(),"corrupt offscreen world rejected before overwriting saves")
 packet.version=999
 t.truth(Voyage.restore(packet).is_empty(),"unknown voyage version rejected")
func test_planet_profiles_are_deterministic_and_different(t: SceneTree) -> void:
 var a: RefCounted=Voyage.new(config())
 var b: RefCounted=Voyage.new(config())
 t.equal(a.configs,b.configs,"same journey generates same three seeds and profiles")
 var worlds: Array=[]
 for rules: Dictionary in a.configs:worlds.append(Campaign.new(rules))
 t.truth(worlds[0].frontier.layout_signature()!=worlds[1].frontier.layout_signature(),"desert layout differs from forest")
 t.truth(worlds[1].frontier.layout_signature()!=worlds[2].frontier.layout_signature(),"ice coast differs from desert")

func test_rocket_payment_needs_workers_and_keeps_partial_investment(t: SceneTree) -> void:
 var voyage: RefCounted=Voyage.new(config())
 var sim: RefCounted=Campaign.new(voyage.configs[0])
 cleared(sim);sim.planet.claim_core();sim.pouch.amount=30
 for i: int in range(15):t.truth(sim.interact(-730,"rocket"),"each deposit spends exactly one crystal")
 var saved: Dictionary=Voyage.restore(voyage.capture(sim,BODY))
 t.truth(not saved.is_empty(),"more than 12 partial rocket deposits survive save")
 t.equal(saved.session.context_for_key(-730,"rocket").paid,15,"partial payment preserved")
 for i: int in range(5):sim.interact(-730,"rocket")
 t.truth(sim.planet.rocket_pending and not sim.planet.rocket_ready,"fully paid scaffold cannot launch before construction")
 t.equal(sim.pouch.amount,10,"rocket consumes 20 crystals")
 sim.advance(2.0,-730)
 t.equal(sim.planet.work,0.0,"rocket does not build without workers")
 sim.world.people[0].role="engineer";sim.world.people[0].x=-730
 for i: int in range(60):sim._engineer_target(0,0.5)
 t.truth(sim.planet.rocket_ready,"nearby engineer completes the rocket")
func test_travel_keeps_module_cooldown_and_merchant_payment(t: SceneTree) -> void:
 var voyage: RefCounted=Voyage.new(config())
 var sim: RefCounted=Campaign.new(voyage.configs[0])
 cleared(sim);sim.planet.claim_core();sim.planet.rocket_ready=true
 sim.modules.found.append("arc");sim.modules.stored.append("arc");sim.modules.equipped="arc"
 for site: RefCounted in sim.trials.sites:
  if site.id=="arc":site.progress=3;site.deadline=0
 sim.modules.ready_tick=roundi(sim.workforce.elapsed*30)+100
 sim.merchant.phase=2;sim.merchant.return_day=0
 var trip: Dictionary=voyage.prepare(sim,BODY,1)
 t.truth(not trip.is_empty(),"travels with an owned module")
 if trip.is_empty():return
 t.equal(trip.session.modules.equipped,"arc","module remains attached")
 t.equal(trip.session.modules.ready_tick,100,"remaining cooldown rebased to the new clock")
 t.equal(trip.session.merchant.phase,2,"merchant remembers gift was already claimed")
 t.truth(not Voyage.restore(trip.journey.capture(trip.session,trip.body)).is_empty(),"carried module and merchant are valid on arrival")
func test_failed_travel_save_keeps_original_session(t: SceneTree) -> void:
 var voyage: RefCounted=Voyage.new(config())
 var sim: RefCounted=Campaign.new(voyage.configs[0])
 cleared(sim);sim.planet.claim_core();sim.planet.rocket_ready=true
 var trip: Dictionary=voyage.prepare(sim,BODY,2)
 var progress: RefCounted=Progress.new(Memory.new())
 t.truth(not progress.save(trip.session,trip.config,trip.body,trip.journey),"store failure prevents travel commit")
 t.equal(voyage.current,0,"preparation does not switch live world")
 t.truth(sim.planet.rocket_ready,"failed transaction leaves original rocket usable")
 t.truth(voyage.planets[2].is_empty(),"failed transaction cannot mark destination visited")
func test_dragon_dead_with_remaining_enemies_can_be_saved(t: SceneTree) -> void:
 var voyage: RefCounted=Voyage.new(config())
 var sim: RefCounted=Campaign.new(voyage.configs[0])
 for rift: Dictionary in sim.mission.rifts:rift.sealed=true
 sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
 sim.raiders.append(sim._spawn_raider())
 t.truth(not sim.planet.cleared,"remaining raider delays core reward")
 t.truth(not Voyage.restore(voyage.capture(sim,BODY)).is_empty(),"saving is legal between dragon death and clearing last enemy")
