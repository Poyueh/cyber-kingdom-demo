extends RefCounted
const Path="res://presentation/campaign_ui_cues.gd"

func test_pause_and_resume_each_click_once(t):
	t.truth(ResourceLoader.exists(Path),"interface cue observer exists")
	if not ResourceLoader.exists(Path):return
	var cues=load(Path).new()
	t.equal(cues.sample(false,true),"","opening a run makes no interface click")
	t.equal(cues.sample(true,true),"ui_pause","pausing clicks once")
	t.equal(cues.sample(true,true),"","holding the pause menu open stays quiet")
	t.equal(cues.sample(false,true),"ui_resume","resuming clicks once")
	t.equal(cues.sample(false,true),"","playing on stays quiet")

func test_unmuting_confirms_itself_but_muting_cannot(t):
	var cues=load(Path).new()
	cues.sample(true,true)
	t.equal(cues.sample(true,false),"","muting cannot announce itself with a sound")
	t.equal(cues.sample(true,true),"ui_mute","unmuting confirms that sound is back")
	t.equal(cues.sample(true,true),"","the confirmation does not repeat")

func test_muting_while_paused_does_not_leave_a_stale_click(t):
	var cues=load(Path).new()
	cues.sample(false,true)
	t.equal(cues.sample(true,false),"","pausing and muting together stays silent")
	t.equal(cues.sample(false,false),"","resuming while muted stays silent")
	t.equal(cues.sample(false,true),"ui_mute","unmuting during play confirms once")
