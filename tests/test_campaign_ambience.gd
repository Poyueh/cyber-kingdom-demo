extends RefCounted
const Session=preload("res://application/campaign_session.gd")
const Path="res://presentation/campaign_ambience_cues.gd"

func _cues():
	return load(Path).new()

func _region_centre(sim, kind: String) -> float:
	for region in sim.frontier.regions:
		if region.kind==kind:return region.x+region.width*0.5
	return 0.0

func test_day_and_night_beds_swap_without_overlapping(t):
	t.truth(ResourceLoader.exists(Path),"ambience cue chooser exists")
	if not ResourceLoader.exists(Path):return
	var cues=_cues()
	var sim=Session.new()
	var far: float=sim.world.sites.hall+9000.0
	var day: Dictionary=cues.sample(sim,far,false)
	t.equal(day.get("amb_day",0.0),1.0,"open daylight runs the daytime bed")
	t.equal(day.get("amb_night",0.0),0.0,"daylight silences the night bed")
	sim.clock.is_night=true
	var night: Dictionary=cues.sample(sim,far,false)
	t.equal(night.get("amb_night",0.0),1.0,"nightfall runs the night bed")
	t.equal(night.get("amb_day",0.0),0.0,"nightfall silences the daytime bed")

func test_landscape_beds_follow_the_knight(t):
	var cues=_cues()
	var sim=Session.new()
	for kind in ["forest","quarry","ruins"]:
		var centre: float=_region_centre(sim,kind)
		if centre==0.0:continue
		var bed: String={"forest":"amb_forest","quarry":"amb_crystal","ruins":"amb_ruins"}[kind]
		var inside: Dictionary=cues.sample(sim,centre,false)
		t.truth(inside.get(bed,0.0)>0.0,"standing in a %s region raises its bed" % kind)
		var away: Dictionary=cues.sample(sim,centre+6000.0,false)
		t.equal(away.get(bed,0.0),0.0,"leaving the %s region drops its bed" % kind)

func test_camp_beds_need_an_actual_camp_and_closeness(t):
	var cues=_cues()
	var sim=Session.new()
	var hall: float=sim.world.sites.hall
	t.equal(cues.sample(sim,hall,false).get("amb_campfire",0.0),0.0,"wilderness before the camp exists has no fire")
	sim.interact(hall)
	sim.interact(hall)
	t.truth(sim.frontier.city_level>0,"camp is established")
	t.truth(cues.sample(sim,hall,false).get("amb_campfire",0.0)>0.0,"standing at the built camp hears the fire")
	t.equal(cues.sample(sim,hall+4000.0,false).get("amb_campfire",0.0),0.0,"walking away leaves the fire behind")
	t.equal(cues.sample(sim,hall,false).get("amb_city",0.0),0.0,"a first level camp is not yet a settlement")
	sim.frontier.city_level=2
	t.truth(cues.sample(sim,hall,false).get("amb_city",0.0)>0.0,"a grown settlement adds its reactor hum")

func test_pause_silences_every_bed(t):
	var cues=_cues()
	var sim=Session.new()
	var paused: Dictionary=cues.sample(sim,sim.world.sites.hall,true)
	for bed in paused:
		t.equal(paused[bed],0.0,"pause silences %s" % bed)
