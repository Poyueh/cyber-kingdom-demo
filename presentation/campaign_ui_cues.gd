extends RefCounted
## Watches the pause menu and the speaker toggle. Muting cannot announce itself,
## so only the return of sound is confirmed. Leaving and returning to the window
## is not a speaker change and must stay silent.
var _paused := false
var _enabled := true
var _started := false

func sample(paused: bool, enabled: bool, suspended: bool) -> String:
	var cue := ""
	if _started and enabled and not suspended:
		if not _enabled:
			cue = "ui_mute"
		elif paused != _paused:
			cue = "ui_pause" if paused else "ui_resume"
	_paused = paused
	_enabled = enabled
	_started = true
	return cue
