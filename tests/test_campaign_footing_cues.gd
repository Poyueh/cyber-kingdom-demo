extends RefCounted
const Path="res://presentation/campaign_footing_cues.gd"

func test_leaving_and_meeting_the_ground_each_sound_once(t):
	t.truth(ResourceLoader.exists(Path),"footing cue observer exists")
	if not ResourceLoader.exists(Path):return
	var cues=load(Path).new()
	t.equal(cues.sample(true,false),"","standing at the start makes no sound")
	t.equal(cues.sample(false,false),"jump","leaving the ground is heard once")
	t.equal(cues.sample(false,false),"","staying in the air is silent")
	t.equal(cues.sample(true,false),"land","meeting the ground is heard once")
	t.equal(cues.sample(true,false),"","standing on it again is silent")

func test_a_paused_or_restored_run_does_not_invent_a_landing(t):
	var cues=load(Path).new()
	cues.sample(true,false)
	cues.sample(false,false)
	t.equal(cues.sample(true,true),"","pause swallows the landing instead of queueing it")
	t.equal(cues.sample(true,false),"","resuming does not replay the swallowed landing")
	var restored=load(Path).new()
	t.equal(restored.sample(false,false),"","a run restored mid-air does not announce a jump")
	t.equal(restored.sample(true,false),"land","the landing after that is still heard")
