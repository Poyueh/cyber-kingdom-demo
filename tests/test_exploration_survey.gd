extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const PATH="res://application/exploration_survey.gd"
func test_survey_respects_discovery_rewards_and_saved_journey(t):
 t.truth(ResourceLoader.exists(PATH),"exploration needs a fog-safe survey")
 if not ResourceLoader.exists(PATH):return
 var survey=load(PATH)
 var config: Dictionary={"seed":73}
 var sim=Campaign.new(config)
 for region in sim.frontier.regions:region.discovered=false
 var hidden: Dictionary=survey.read(sim,30.0)
 t.equal(hidden.markers.size(),1,"unexplored treasure, modules and gates stay hidden; only camp is known")
 t.truth(hidden.regions.all(func(r):return r.kind=="unknown" and r.title=="未探索"),"unexplored region names cannot leak terrain")
 var cache: RefCounted=sim.frontier.nodes.filter(func(n):return n.kind=="cache")[0]
 sim.frontier.regions[cache.region].discovered=true
 var seen: Dictionary=survey.read(sim,cache.x)
 t.truth(seen.markers.any(func(m):return m.kind=="chest" and m.x==cache.x),"discovered treasure appears at its actual location")
 cache.collected=true;cache.delivered=true
 t.truth(not survey.read(sim,cache.x).markers.any(func(m):return m.kind=="chest" and m.x==cache.x),"opened treasure is not advertised as an available reward")
 var relic=sim.modules.relics[0]
 sim.frontier.regions[relic.region].discovered=true
 t.truth(survey.read(sim,relic.x).markers.any(func(m):return m.kind=="gear" and m.x==relic.x),"discovered module is shown before pickup")
 sim.modules.found.append(relic.id);sim.modules.stored.append(relic.id);sim.modules.equipped=relic.id
 t.truth(not survey.read(sim,relic.x).markers.any(func(m):return m.kind=="gear" and m.x==relic.x),"found module no longer appears as unclaimed")
 var codec=Codec.new();var body: Dictionary={"x":relic.x,"y":430.0,"vx":0.0,"vy":0.0}
 var before: Dictionary=codec.capture(sim,config,body)
 survey.read(sim,relic.x)
 t.equal(JSON.stringify(codec.capture(sim,config,body)),JSON.stringify(before),"reading the map never changes gameplay or discovery")
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(before)))
 t.truth(not restored.is_empty(),"exploration state still uses existing compatible saves")
 if restored.is_empty():return
 t.equal(survey.read(restored.session,relic.x),survey.read(sim,relic.x),"survey survives a real JSON save round trip")
