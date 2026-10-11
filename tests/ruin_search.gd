extends RefCounted
## Exhaustive button sequences, independent of layout generation. Never used by gameplay.
static func actions(mechanism: RefCounted) -> Array[int]:
	if mechanism.kind==3:return [0,1,2]
	var saved: Dictionary=mechanism.capture();var progress: int=mechanism.progress()
	var base: int=2 if mechanism.kind==2 else 3
	var limit: int=6 if mechanism.kind==2 else 3
	for length: int in range(1,limit+1):
		for word: int in range(int(pow(base,length))):
			mechanism.restore(saved,progress)
			var remaining: int=word;var path: Array[int]=[];var accepted: bool=true
			for step: int in range(length):
				var action: int=remaining%base;remaining=int(remaining/base)
				path.append(action)
				if not mechanism.activate(action,0):accepted=false;break
			if mechanism.kind==2:path.append(2);accepted=mechanism.activate(2,0) and accepted
			if accepted and mechanism.progress()==3:
				mechanism.restore(saved,progress);return path
	mechanism.restore(saved,progress)
	return []
static func next_tick(mechanism: RefCounted, station: int, now: int) -> int:
	if mechanism.kind!=3:return now
	# Select the middle of a visible opening, leaving margin for input frames.
	var center: int=int(mechanism.window/2)
	return now+posmod(center-mechanism.phase(station,now),mechanism.period)
