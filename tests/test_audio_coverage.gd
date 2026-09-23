extends RefCounted
## Guards the v002 set against silent drift: every sound the rack can play must
## exist on disk, and every generated sound must be triggered by something. The
## pending list is empty, and a new asset that nothing plays will fail here.
const Rack=preload("res://presentation/campaign_audio.gd")

## Sources that decide when a sound plays. The asset table inside the rack is
## excluded, otherwise every sound would look wired by merely existing.
const DECIDERS=[
	"res://presentation/campaign_audio_cues.gd",
	"res://presentation/campaign_ui_cues.gd",
	"res://presentation/campaign_pulse_cues.gd",
	"res://presentation/campaign_loop_cues.gd",
	"res://presentation/campaign_footing_cues.gd",
	"res://presentation/arena_audio_cues.gd",
	"res://presentation/title_audio.gd",
	"res://bootstrap/frontier_root.gd",
	"res://bootstrap/start_menu_root.gd",
]

## Generated but deliberately not triggered by anything. Emptying this list was
## the remaining audio work; adding to it needs a reason in the design notes.
const PENDING: Array[String]=[]

func _sources() -> String:
	var text := ""
	for path in DECIDERS:
		text += FileAccess.get_file_as_string(path)
	var rack := FileAccess.get_file_as_string("res://presentation/campaign_audio.gd")
	var table := rack.find("const SOUNDS=")
	var after := rack.find("signal cue_requested")
	text += rack.substr(0, table) + rack.substr(after)
	return text

func _wired() -> Array:
	var sources := _sources()
	var found: Array = []
	for kind in Rack.SOUNDS:
		if sources.contains('"%s"' % kind): found.append(kind)
	return found

func test_the_asset_table_can_be_told_apart_from_playback(t):
	var rack := FileAccess.get_file_as_string("res://presentation/campaign_audio.gd")
	t.truth(rack.find("const SOUNDS=") >= 0, "the asset table is findable")
	t.truth(rack.find("signal cue_requested") > rack.find("const SOUNDS="), "playback code follows the table")

func test_every_playable_sound_has_its_file(t):
	var missing: Array = []
	for kind in Rack.SOUNDS:
		for stream in Rack.SOUNDS[kind]:
			if stream == null: missing.append(kind)
	t.equal(missing, [], "every sound the rack lists is loadable")
	t.truth(Rack.SOUNDS.size() >= 70, "the full effect set is present, not a stub")

func test_no_generated_sound_is_left_without_a_trigger(t):
	var wired := _wired()
	var silent: Array = []
	for kind in Rack.SOUNDS:
		if not wired.has(kind) and not PENDING.has(kind): silent.append(kind)
	silent.sort()
	t.equal(silent, [], "every generated sound is played by something")

func test_the_pending_list_stays_honest(t):
	var wired := _wired()
	var contradictions: Array = []
	for kind in PENDING:
		if wired.has(kind): contradictions.append(kind)
	t.equal(contradictions, [], "a wired sound is not still listed as pending")
	t.equal(PENDING, [] as Array[String], "nothing generated is deliberately silent")

func test_constant_texture_never_cuts_off_a_decisive_sound(t):
	var protected := ["footstep","footstep_slow","work_chop","work_mine","work_hammer",
		"work_harvest","pickup","pay","crystal_land"]
	for kind in protected:
		t.truth(Rack.QUIET_ENOUGH_TO_DROP.has(kind),
			"%s gives up its voice instead of stealing one" % kind)
	var decisive := ["hit","heavy","hurt","death","victory","defeat","core_hit",
		"dragon_arrival","enemy_telegraph","raid_warning","seal"]
	for kind in decisive:
		t.truth(not Rack.QUIET_ENOUGH_TO_DROP.has(kind),
			"%s is never dropped to make room" % kind)

func test_every_generated_track_and_bed_is_reachable(t):
	var music := FileAccess.get_file_as_string("res://presentation/campaign_music_cues.gd")
	var player := FileAccess.get_file_as_string("res://presentation/campaign_music.gd")
	var loops: Array = load("res://presentation/campaign_music.gd").LOOPS
	var stings: Array = load("res://presentation/campaign_music.gd").STINGS
	var unreachable: Array = []
	for name in DirAccess.get_files_at("res://art/audio/music-v002"):
		var track := str(name).trim_suffix(".remap").trim_suffix(".import")
		if not track.ends_with(".ogg"): continue
		track = track.trim_suffix(".ogg")
		if loops.has(track) or stings.has(track): continue
		if music.contains('"%s"' % track) or player.contains('"%s"' % track): continue
		unreachable.append(track)
	unreachable.sort()
	t.equal(unreachable, [], "every generated music track can be chosen")

	var beds: Array = load("res://presentation/campaign_ambience_cues.gd").BEDS
	var orphan: Array = []
	for name in DirAccess.get_files_at("res://art/audio/ambience-v002"):
		var bed := str(name).trim_suffix(".remap").trim_suffix(".import")
		if not bed.ends_with(".ogg"): continue
		bed = bed.trim_suffix(".ogg")
		if not beds.has(bed): orphan.append(bed)
	orphan.sort()
	t.equal(orphan, [], "every generated ambience bed is part of the mix")
