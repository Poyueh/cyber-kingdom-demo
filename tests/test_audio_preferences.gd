extends RefCounted
const Preferences=preload("res://infrastructure/audio_preferences.gd")
func test_volume_preferences_round_trip_and_protect_corrupt_input(t):
	var path="user://test_preferences_%d.cfg" % Time.get_ticks_usec()
	var prefs=Preferences.new(path)
	t.equal(prefs.read(),{"music":0.4,"effects":0.8,"ambience":0.6,"muted":false},"missing settings use audible defaults")
	t.truth(prefs.write(0.25,0,0.35,false),"volume preferences save independently of game progress")
	t.equal(Preferences.new(path).read(),{"music":0.25,"effects":0.0,"ambience":0.35,"muted":false},"every channel survives reopening")
	var corrupt='[audio]\nmusic="invalid"\n'
	var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(corrupt);file.close()
	prefs=Preferences.new(path);prefs.read()
	t.truth(not prefs.write(1,1,1,false),"malformed settings are protected")
	t.equal(FileAccess.get_file_as_string(path),corrupt,"invalid original is not silently replaced")
	DirAccess.remove_absolute(path)

func test_settings_written_before_ambience_existed_keep_their_volumes(t):
	var path="user://test_preferences_old_%d.cfg" % Time.get_ticks_usec()
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string('[audio]\nmusic=0.22\neffects=0.63\n');file.close()
	var prefs=Preferences.new(path)
	t.equal(prefs.read(),{"music":0.22,"effects":0.63,"ambience":0.6,"muted":false},"an older file keeps its levels and gains the new default")
	t.truth(prefs.write(0.22,0.63,0.1,false),"an older file is still writable")
	DirAccess.remove_absolute(path)

func test_mute_survives_restarting_the_app(t):
	var path="user://test_preferences_mute_%d.cfg" % Time.get_ticks_usec()
	var prefs=Preferences.new(path)
	t.equal(prefs.read().muted,false,"sound starts on")
	t.truth(prefs.write(0.4,0.8,0.6,true),"a muted session is saved")
	t.equal(Preferences.new(path).read().muted,true,"reopening the app keeps sound muted")
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string('[audio]\nmuted="yes"\n');file.close()
	var broken=Preferences.new(path)
	t.equal(broken.read().muted,false,"a malformed mute setting falls back to audible")
	t.truth(not broken.write(0.4,0.8,0.6,false),"a malformed file is not silently replaced")
	DirAccess.remove_absolute(path)
