extends RefCounted
## Watches the pause menu and the speaker toggle. Muting cannot announce itself,
## so only the return of sound is confirmed.
var _paused := false
var _enabled := true
var _started := false

func sample(paused: bool, enabled: bool) -> String:
	var cue := ""
	if _started and enabled:
		if enabled and not _enabled:
			cue = "ui_mute"
		elif paused != _paused:
			cue = "ui_pause" if paused else "ui_resume"
	_paused = paused
	_enabled = enabled
	_started = true
	return cue
