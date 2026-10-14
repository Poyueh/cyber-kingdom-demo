extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Voyage=preload("res://application/star_voyage.gd")
const Existing=preload("res://tests/test_star_voyage.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func test_free_destination_with_first_reactor_and_no_branch_cores(t: SceneTree) -> void:
 var journey: RefCounted=Voyage.new(Existing.new().config(),preload("res://tests/test_seven_worlds.gd").new().profiles())
 var sim: RefCounted=Campaign.new(journey.configs[0])
 Existing.new().cleared(sim);sim.planet.claim_core();sim.planet.rocket_ready=true
 for target: int in [6,4,3,5,2,1]:
  var trip: Dictionary=journey.prepare(sim,Existing.BODY,target)
  t.truth(not trip.is_empty(),"first reactor permits freely choosing planet %d"%target)
 sim.planet.rocket_ready=false
 t.truth(journey.prepare(sim,Existing.BODY,6).is_empty(),"free destinations still require a constructed rocket")
func test_multiple_gates_preserve_pressure_until_whole_side_is_sealed(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new({"seed":46,"rift_layout_version":1,"rift_left_count":2,"rift_right_count":2})
 t.equal(sim.mission.rifts.size(),4,"two gates per side are actually created")
 if sim.mission.rifts.size()!=4:return
 var inner: float=sim.mission.entry_x(-1)
 var gate: Dictionary=sim.mission.rifts.filter(func(r: Dictionary)->bool:return r.x==inner)[0]
 gate.sealed=true
 t.truth(sim.mission.side_open(-1),"one sealed gate does not silence the other gate on that side")
 t.truth(sim.mission.entry_x(-1)<inner-600,"night entry retreats outward after sealing inner gate")
 sim.mission.dragon_defeated=true;sim.mission.resolve(true,true)
 t.equal(sim.mission.outcome,"active","partial seals cannot win")
 for rift: Dictionary in sim.mission.rifts:rift.sealed=true
 t.truth(not sim.mission.side_open(-1) and not sim.mission.side_open(1),"all gates closed stop both sides")
 sim.mission.resolve(true,true)
 t.equal(sim.mission.outcome,"victory","four sealed gates can complete a world")
func test_gate_layout_checkpoint_retains_multiple_and_legacy_worlds(t: SceneTree) -> void:
 for count: int in [1,2]:
  var config: Dictionary={"seed":46}
  if count==2:config.merge({"rift_layout_version":1,"rift_left_count":2,"rift_right_count":2})
  var sim: RefCounted=Campaign.new(config)
  var packet: Dictionary=Codec.new().capture(sim,config,Existing.BODY)
  t.equal(sim.mission.rifts.size(),count*2,"legacy remains two, new authored world has four gates")
  t.truth(not Codec.new().restore(JSON.parse_string(JSON.stringify(packet))).is_empty(),"gate layout round-trips without regenerating a saved world")
  packet.mission.rifts.pop_back()
  t.truth(Codec.new().restore(packet).is_empty(),"missing gate is corruption, not a partial expedition")

func test_a_partial_seal_keeps_the_night_quota_and_saved_thief_exit(t: SceneTree) -> void:
 var config: Dictionary=preload("res://data/campaign.tres").campaign_rules()
 config.merge({"seed":46,"rift_layout_version":1,"rift_left_count":2,"rift_right_count":1})
 var sim: RefCounted=Campaign.new(config)
 sim.frontier.city_level=1;sim.survival.armed=true
 var before: int=sim.planned_night_count()
 var entry: float=sim.mission.entry_x(-1)
 var thief: Dictionary=sim._spawn_raider();thief.x=entry+30;thief["side"]=-1;thief["carried_crystals"]=1;thief["retreat_x"]=entry
 sim.raiders.append(thief)
 for gate: Dictionary in sim.mission.rifts:
  if gate.x==entry:gate.sealed=true
 t.equal(sim.planned_night_count(),before,"adding and sealing gates does not multiply the nightly quota")
 var saved: Dictionary=Codec.new().capture(sim,config,Existing.BODY)
 t.truth(not Codec.new().restore(JSON.parse_string(JSON.stringify(saved))).is_empty(),"thief may retain its previous exit while another gate becomes active")
 saved.raiders[0].state.retreat_x=0.0
 t.truth(Codec.new().restore(saved).is_empty(),"thief cannot forge a retreat destination that is not a gate")
 sim.raiders.clear();sim.clock.is_night=true;sim.clock.remaining=20;sim._spawn_remaining=2;sim._spawn_timer=0;sim._night_spawn_index=1
 sim._advance_invasion(0.1)
 t.truth(sim.raiders.any(func(e: Dictionary)->bool:return e.get("side",0)==-1),"sealing inner left gate still allows a real left invasion")
 for enemy: Dictionary in sim.raiders:
  if enemy.get("side",0)==-1:t.truth(enemy.x<entry-600,"real enemy emerges at the remaining outer gate")

func test_legacy_route_masks_do_not_restrict_a_restored_journey(t: SceneTree) -> void:
 var profiles: Array[Dictionary]=preload("res://tests/test_seven_worlds.gd").new().profiles()
 profiles[6].route_requires=32
 var journey: RefCounted=Voyage.new(Existing.new().config(),profiles)
 var sim: RefCounted=Campaign.new(journey.configs[0])
 Existing.new().cleared(sim);sim.planet.claim_core();sim.planet.rocket_ready=true
 var restored: Dictionary=Voyage.restore(journey.capture(sim,Existing.BODY))
 t.truth(not restored.is_empty(),"historical route-mask journey is still readable")
 if restored.is_empty():return
 var trip: Dictionary=restored.journey.prepare(restored.session,Existing.BODY,6)
 t.truth(not trip.is_empty(),"old journey can travel to the void without a storm core")
 if trip.is_empty():return
 t.equal(trip.journey.configs[6].route_requires,32,"free navigation does not rewrite old stored rules")
 t.equal(trip.session.mission.rifts.size(),2,"old unvisited world still uses its original two gates")
