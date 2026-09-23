extends RefCounted
const Session=preload("res://application/campaign_session.gd")
func test_sound_observation_does_not_replay_effects_or_invent_payments(t):
 var path="res://presentation/campaign_audio_cues.gd"
 t.truth(ResourceLoader.exists(path),"campaign audio cue observer exists")
 if not ResourceLoader.exists(path):return
 var cues=load(path).new()
 var sim=Session.new()
 t.equal(cues.sample(sim,30,false),[],"opening or restored state makes no historical sound")
 sim.interact(30)
 t.equal(cues.sample(sim,30,false),["pay"],"one real crystal payment sounds once")
 t.equal(cues.sample(sim,30,false),[],"same persistent visual effect does not repeat its sound")
 sim.interact(30)
 t.truth("build" in cues.sample(sim,30,false),"actual completed camp adds construction feedback")
 sim.effects.clear()
 sim.effects.append({"kind":"crystal_pickup","x":30,"life":0.25})
 sim.effects.append({"kind":"crystal_pickup","x":30,"life":0.25})
 t.equal(cues.sample(sim,30,false),["pickup"],"simultaneous identical pickups coalesce to one cue")
 sim.effects.append({"kind":"pay","x":30,"life":0.45})
 t.equal(cues.sample(sim,30,true),[],"pause consumes pending feedback silently")
 t.equal(cues.sample(sim,30,false),[],"resume never replays paused feedback")
 var replacement=Session.new()
 replacement.interact(30)
 t.equal(cues.sample(replacement,30,false),[],"restart or restore primes a new session without replay")
 t.equal(sim.pouch.amount,10,"audio observation never changes resources")

func test_sounds_follow_active_cuts_hits_distance_and_end_states(t):
 var cues=load("res://presentation/campaign_audio_cues.gd").new()
 var sim=Session.new()
 cues.sample(sim,30,false)
 sim.hero.start_attack()
 t.equal(cues.sample(sim,30,false),[],"windup is silent until blade becomes active")
 sim.hero.advance(sim.hero.stats.attack_duration*0.42)
 t.equal(cues.sample(sim,30,false),["slash1"],"active first cut sounds at the striking pose")
 t.equal(cues.sample(sim,30,false),[],"same active cut never loops its whoosh")
 sim.effects.append({"kind":"hit","x":35,"life":0.2,"heavy":true})
 t.equal(cues.sample(sim,30,false),["heavy"],"real finisher impact has its own cue")
 sim.effects.append({"kind":"hit","x":2000,"life":0.2})
 t.equal(cues.sample(sim,30,false),[],"distant offscreen battle stays quiet")
 t.equal(cues.sample(sim,2000,false),[],"moving toward old impact cannot replay it")
 sim.hero.start_dash()
 t.equal(cues.sample(sim,30,false),["dash"],"successful dash creates one mechanical burst")
 sim.hero.invulnerability_remaining=0
 sim.hero.shield=20
 sim.hero.take_damage(10)
 t.truth("shield" in cues.sample(sim,30,false),"shield absorption has its own deflection sound")
 sim.clock.is_night=true
 t.equal(cues.sample(sim,30,false),["night"],"real night transition gives one warning")
 sim.mission.rifts[0].sealed=true
 t.equal(cues.sample(sim,30,false),["seal"],"completed seal sounds once")
 sim.mission.outcome="victory"
 t.equal(cues.sample(sim,30,false),["victory"],"terminal result plays once")
 t.equal(cues.sample(sim,30,false),[],"victory screen does not loop result sound")
