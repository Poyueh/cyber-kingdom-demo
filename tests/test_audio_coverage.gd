extends RefCounted
## Guards the v002 set against silent drift: every sound the rack can play must
## exist on disk, and every generated sound must either be wired or be listed
## here as still pending. A new asset cannot be quietly forgotten.
const Rack=preload("res://presentation/campaign_audio.gd")

## Generated, approved, but not yet triggered by anything. Emptying this list is
## the remaining audio work; adding to it needs a reason in the design notes.
const PENDING=[
	"arrow_hit","charge_empty","crystal_land","dragon_wing","enemy_attack","enemy_grab",
	"enemy_telegraph","farewell","footstep","footstep_slow","gatekeeper_appear","handoff",
	"horse_gallop","kingdom","mount","raid_warning","resident_hit","seal_progress",
	"slot_complete","slot_refund","tool_pickup","ui_confirm","ui_save","ui_select",
	"work_chop","work_hammer","work_harvest","work_mine",
]

func _wired() -> Array:
	var sources := ""
	for path in ["res://presentation/campaign_audio_cues.gd","res://presentation/campaign_ui_cues.gd"]:
		sources += FileAccess.get_file_as_string(path)
	# The rack itself only names sounds it plays outside the asset table.
	var rack := FileAccess.get_file_as_string("res://presentation/campaign_audio.gd")
	var table := rack.find("const SOUNDS=")
	var after := rack.find("signal cue_requested")
	sources += rack.substr(0, table) + rack.substr(after)
	var found: Array = []
	for kind in Rack.SOUNDS:
		if sources.contains('"%s"' % kind): found.append(kind)
	for step in ["slash1","slash2","slash3"]:
		if sources.contains("slash%d") and not found.has(step): found.append(step)
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

func test_pending_list_matches_what_is_actually_unwired(t):
	var wired := _wired()
	var unwired: Array = []
	for kind in Rack.SOUNDS:
		if not wired.has(kind): unwired.append(kind)
	unwired.sort()
	var pending := PENDING.duplicate()
	pending.sort()
	t.equal(unwired, pending, "the pending list is the real list of silent assets")

func test_nothing_pending_is_also_wired(t):
	var wired := _wired()
	var contradictions: Array = []
	for kind in PENDING:
		if wired.has(kind): contradictions.append(kind)
	t.equal(contradictions, [], "a wired sound is not still listed as pending")
