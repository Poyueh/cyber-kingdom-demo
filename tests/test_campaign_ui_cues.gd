extends RefCounted
const Path="res://presentation/campaign_ui_cues.gd"

func test_pause_and_resume_each_click_once(t):
	t.truth(ResourceLoader.exists(Path),"interface cue observer exists")
	if not ResourceLoader.exists(Path):return
	var cues=load(Path).new()
	t.equal(cues.sample(false,true,false),"","opening a run makes no interface click")
	t.equal(cues.sample(true,true,false),"ui_pause","pausing clicks once")
	t.equal(cues.sample(true,true,false),"","holding the pause menu open stays quiet")
	t.equal(cues.sample(false,true,false),"ui_resume","resuming clicks once")
	t.equal(cues.sample(false,true,false),"","playing on stays quiet")

func test_unmuting_confirms_itself_but_muting_cannot(t):
	var cues=load(Path).new()
	cues.sample(true,true,false)
	t.equal(cues.sample(true,false,false),"","muting cannot announce itself with a sound")
	t.equal(cues.sample(true,true,false),"ui_mute","unmuting confirms that sound is back")
	t.equal(cues.sample(true,true,false),"","the confirmation does not repeat")

func test_muting_while_paused_does_not_leave_a_stale_click(t):
	var cues=load(Path).new()
	cues.sample(false,true,false)
	t.equal(cues.sample(true,false,false),"","pausing and muting together stays silent")
	t.equal(cues.sample(false,false,false),"","resuming while muted stays silent")
	t.equal(cues.sample(false,true,false),"ui_mute","unmuting during play confirms once")

func test_leaving_and_returning_to_the_window_is_not_a_speaker_change(t):
	var cues=load(Path).new()
	cues.sample(false,true,false)
	t.equal(cues.sample(false,true,true),"","losing the window makes no click")
	t.equal(cues.sample(false,true,false),"","coming back does not pretend the speaker was turned on")
	t.equal(cues.sample(true,true,false),"ui_pause","the pause menu still clicks after coming back")

func test_backgrounding_a_paused_game_replays_nothing_on_return(t):
	var cues=load(Path).new()
	cues.sample(false,true,false)
	t.equal(cues.sample(true,true,false),"ui_pause","the player pauses and hears it")
	t.equal(cues.sample(true,true,true),"","leaving the app while paused stays silent")
	t.equal(cues.sample(true,true,false),"","returning to the same paused menu replays nothing")
	t.equal(cues.sample(false,true,false),"ui_resume","actually resuming still clicks")
