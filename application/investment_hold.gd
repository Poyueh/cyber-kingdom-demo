extends RefCounted
## One deliberate gesture funds one project. It never follows a different target.
var target_key: String = ""
var _down := false
var _waiting_for_release := false
var _remaining := 0.0
var _period := 0.0
var _initial_delay: float
var _interval: float

func _init(initial_delay: float = 0.5, interval: float = 0.28) -> void:
	_initial_delay=maxf(0.2,initial_delay)
	_interval=maxf(0.1,interval)

func step(seconds: float, held: bool, allowed: bool, session, x: float) -> bool:
	if not held:
		if session.has_method("cancel_investment"):session.cancel_investment(target_key,x)
		_down=false
		_waiting_for_release=false
		target_key=""
		return false
	if seconds<=0 or not is_finite(seconds): return false
	if not allowed:
		if session.has_method("cancel_investment"):session.cancel_investment(target_key,x)
		cancel()
		return false
	if _waiting_for_release: return false
	if not _down:
		_down=true
		var choice: Dictionary=session.context(x)
		if not choice.enabled:
			cancel()
			return false
		target_key=choice.key
		return _invest(session,x,choice,_initial_delay)
	var choice: Dictionary=session.context_for_key(x,target_key)
	if not choice.enabled:
		if session.has_method("cancel_investment"):session.cancel_investment(target_key,x)
		cancel()
		return false
	_remaining-=seconds
	if _remaining>0: return false
	return _invest(session,x,choice,_interval)

func _invest(session, x: float, choice: Dictionary, next_delay: float) -> bool:
	if not session.interact(x,target_key):
		cancel()
		return false
	if choice.cost<=0 or choice.paid+1>=choice.cost:
		cancel()
	else:
		_period=next_delay
		_remaining=next_delay
	return true

func cancel() -> void:
	_down=true
	_waiting_for_release=true
	target_key=""

func progress() -> float:
	if target_key.is_empty() or _period<=0: return 0.0
	return clampf(1.0-_remaining/_period,0,1)
