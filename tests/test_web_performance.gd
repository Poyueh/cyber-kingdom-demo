extends RefCounted
## Phones get hot when the web build renders as fast as a 90-120 Hz screen allows.
## The frame cap depends only on the platform the game runs on.
const Profile=preload("res://data/web_performance.gd")

func profile() -> Resource:
	return load("res://data/web_performance.tres")

func test_web_phones_render_at_most_thirty_frames(t):
	var p: Resource=profile()
	t.equal(p.frame_cap(PackedStringArray(["web","web_android"])),30,"Android browsers are capped at 30 frames per second")
	t.equal(p.frame_cap(PackedStringArray(["web","web_ios"])),30,"iPhone and iPad browsers are capped at 30 frames per second")
	t.equal(p.frame_cap(PackedStringArray(["web","web_macos"])),60,"desktop browsers stop at 60 even on fast screens")
	t.equal(p.frame_cap(PackedStringArray(["macos","pc"])),0,"native builds keep vsync and no extra cap")
	t.equal(p.frame_cap(PackedStringArray(["ios","mobile"])),0,"the native phone app is unchanged")

## The simulation, knight and HUD update on every physics tick, whatever the frame cap.
func test_web_phones_update_physics_thirty_times_a_second(t):
	var p: Resource=profile()
	t.equal(p.physics_rate(PackedStringArray(["web","web_android"])),30,"Android browsers step physics 30 times a second")
	t.equal(p.physics_rate(PackedStringArray(["web","web_ios"])),30,"iPhone browsers step physics 30 times a second")
	t.equal(p.physics_rate(PackedStringArray(["web","web_macos"])),0,"desktop browsers keep the project rate")
	t.equal(p.physics_rate(PackedStringArray(["ios","mobile"])),0,"the native phone app keeps the project rate")

func test_web_music_streams_instead_of_decoding_whole_tracks(t):
	var p: Resource=profile()
	t.equal(p.music_playback(PackedStringArray(["web","web_ios"])),AudioServer.PLAYBACK_TYPE_STREAM,"web music streams, saving about 40 MB per track")
	t.equal(p.music_playback(PackedStringArray(["macos","pc"])),AudioServer.PLAYBACK_TYPE_DEFAULT,"native builds keep the project default")
