extends RefCounted
## Watches the knight leave and meet the ground. The campaign is flat, so leaving
## the floor is a leap rather than a fall.
var _grounded := true
var _started := false

func sample(grounded: bool, paused: bool) -> String:
	var cue := ""
	if _started and not paused and grounded != _grounded:
		cue = "land" if grounded else "jump"
	_grounded = grounded
	_started = true
	return cue
