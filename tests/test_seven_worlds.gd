extends RefCounted
const Voyage = preload("res://application/star_voyage.gd")
const Campaign = preload("res://application/campaign_session.gd")
const Existing = preload("res://tests/test_star_voyage.gd")
const BODY = Existing.BODY
func profiles() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for name: String in ["forest", "desert", "frost", "swamp", "volcanic", "storm", "void"]:
  var path: String = "res://data/planets/%s.tres" % name
  if ResourceLoader.exists(path):result.append(load(path).rules())
 return result
func win(sim: RefCounted) -> void:
 Existing.new().cleared(sim)
 sim.planet.claim_core()
 sim.planet.rocket_ready = true
func test_seven_core_route_and_return_preserve_worlds(t: SceneTree) -> void:
 var journey: RefCounted = Voyage.new(Existing.new().config(), profiles())
 t.equal(journey.configs.size(), 7, "seven worlds exist as playable configurations")
 if journey.configs.size() != 7:return
 var sim: RefCounted = Campaign.new(journey.configs[0])
 win(sim)
 t.truth(journey.prepare(sim, BODY, 6).is_empty(), "first core cannot skip straight to last dragon")
 var visited: Array[int] = [1, 3, 2, 4, 5, 6]
 for id: int in visited:
  var trip: Dictionary = journey.prepare(sim, BODY, id)
  t.truth(not trip.is_empty(), "route reaches world %d after its predecessor cores" % id)
  if trip.is_empty():return
  journey = trip.journey;sim = trip.session
  t.equal(sim.planet.id, id, "destination has its own planet identity")
  win(sim);journey.observe(sim)
  t.equal(sim.mission.outcome, "victory" if id == 6 else "active", "only seventh core ends the expedition")
  var packet: Dictionary = journey.capture(sim, BODY)
  var restored: Dictionary = Voyage.restore(JSON.parse_string(JSON.stringify(packet)))
  t.truth(not restored.is_empty(), "seven-world JSON roundtrip remains valid")
  if restored.is_empty():return
  journey = restored.journey;sim = restored.session
 t.equal(journey.core_count(sim), 7, "all seven distinct cores count exactly once")
func test_old_three_world_victory_can_continue_into_four_new_worlds(t: SceneTree) -> void:
 var old: RefCounted = Voyage.new(Existing.new().config())
 var sim: RefCounted = Campaign.new(old.configs[0])
 win(sim)
 for id: int in [1,2]:
  var trip: Dictionary=old.prepare(sim,BODY,id)
  old=trip.journey;sim=trip.session;win(sim)
 sim.planet.completed=true;sim.mission.outcome="victory"
 var packet: Dictionary = old.capture(sim, BODY)
 packet.format = "three_planets";packet.version = 1
 packet.configs.resize(3);packet.planets.resize(3)
 var restored: Dictionary = Voyage.restore(packet)
 t.truth(not restored.is_empty(), "existing three-world checkpoint is still readable")
 if restored.is_empty():return
 if not restored.journey.has_method("expand"):t.truth(false, "legacy journey can expand without resetting its town");return
 restored.journey.expand(profiles(), restored.session)
 t.equal(restored.journey.configs.size(), 7, "migration appends four definitions")
 t.equal(restored.session.mission.outcome,"active","old three-core victory resumes as a seven-world expedition")
 t.equal(restored.journey.core_count(restored.session),3,"all three old cores are retained")
 t.truth(restored.session.planet.core_claimed, "existing core is retained")
 t.equal(restored.session.frontier.city_level, 1, "existing settlement is retained")
 t.truth(not Voyage.restore(restored.journey.capture(restored.session, BODY)).is_empty(), "migrated journey saves in seven-world envelope")
func test_route_cannot_bypass_uncleared_branch_by_returning_home(t: SceneTree) -> void:
 var journey: RefCounted = Voyage.new(Existing.new().config(), profiles())
 if journey.configs.size() != 7:t.truth(false, "route gate test requires seven planets");return
 var sim: RefCounted = Campaign.new(journey.configs[0]);win(sim)
 var trip: Dictionary = journey.prepare(sim, BODY, 1)
 t.truth(not trip.is_empty(), "forest unlocks desert")
 if trip.is_empty():return
 trip.session.planet.rocket_ready = true
 t.truth(trip.journey.prepare(trip.session, BODY, 3).is_empty(), "unbeaten desert cannot unlock swamp")
 var back: Dictionary = trip.journey.prepare(trip.session, BODY, 0)
 t.truth(not back.is_empty(), "may escape undefeated desert by rebuilding and returning")
 if back.is_empty():return
 back.session.planet.rocket_ready = true
 t.truth(back.journey.prepare(back.session, BODY, 3).is_empty(), "home cannot bypass branch gate")
 t.truth(not back.journey.prepare(back.session, BODY, 2).is_empty(), "other unlocked branch remains available")
func test_dragon_sequence_resumes_identically_after_mid_attack_save(t: SceneTree) -> void:
 var defs: Array[Dictionary]=profiles()
 for id: int in [3,4,5,6]:
  var journey: RefCounted=Voyage.new(Existing.new().config(),defs)
  var origin: RefCounted=Campaign.new(journey.configs[0]);win(origin)
  journey.planets[0]={"campaign":preload("res://application/campaign_snapshot.gd").new().capture(origin,journey.configs[0],BODY),"planet":origin.planet.capture()}
  journey.current=id
  var sim: RefCounted=Campaign.new(journey.configs[id]);sim.planet.reactor=true
  sim.frontier.city_level=1;sim.survival.armed=true
  for rift: Dictionary in sim.mission.rifts:rift.sealed=true
  sim.advance(0.1,3000,430)
  var dragon: Dictionary=sim.raiders.filter(func(e: Dictionary)->bool:return e.get("kind","")=="dragon")[0]
  dragon.x=2700.0;dragon.direction=1.0;dragon.cooldown=0.0;dragon.windup=0.1;dragon.target={"kind":"hero","x":3000.0}
  sim.advance(0.15,4000,430)
  var body: Dictionary={"x":4000.0,"y":430.0,"vx":0.0,"vy":0.0}
  var packet: Dictionary=journey.capture(sim,body)
  var restored: Dictionary=Voyage.restore(JSON.parse_string(JSON.stringify(packet)))
  t.truth(not restored.is_empty(),"mid-volley checkpoint for dragon %d is valid"%id)
  if restored.is_empty():return
  for tick: int in range(150):
   sim.advance(1.0/30,4000,430);restored.session.advance(1.0/30,4000,430)
  t.truth(JSON.parse_string(JSON.stringify(journey.capture(sim,body))) == JSON.parse_string(JSON.stringify(restored.journey.capture(restored.session,body))),"dragon %d continues same attack, cooldown, people and crystals after load"%id)
