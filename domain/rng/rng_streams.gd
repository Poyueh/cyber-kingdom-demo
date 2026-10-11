extends RefCounted
## One sequence per purpose. Adding a draw to one system must never shift the
## dice of another, so streams are derived from the run seed and never shared.
enum Stream {WORLD, LOOT, EVENT, COMBAT, RUIN_LAYOUT}
const STREAM_SALT: Array[int]=[0x9E3779B1,0x85EBCA77,0x1B873593,0x27D4EB2F,0x165667B1]
## The two murmur3 finalisation constants, written signed because GDScript
## integers are 64-bit signed (0xFF51AFD7ED558CCD and 0xC4CEB9FE1A85EC53).
const MIX_A := -51049160248110899
const MIX_B := -4265267296055464877

var master_seed: int = 0
var _streams: Dictionary={}

func _init(seed_value: int = 0) -> void:
	master_seed=seed_value
	for stream in Stream.values():
		var generator := RandomNumberGenerator.new()
		generator.seed=_derive(seed_value,stream)
		_streams[stream]=generator

## Avalanche mix so neighbouring run seeds do not produce neighbouring streams.
static func _derive(seed_value: int, stream: int) -> int:
	var value: int=seed_value^STREAM_SALT[stream]
	value=(value^(value>>33))*MIX_A
	value=(value^(value>>33))*MIX_B
	return value^(value>>33)

func of(stream: Stream) -> RandomNumberGenerator:
	return _streams[stream]

func roll(stream: Stream, chance: float) -> bool:
	if chance<=0.0:
		return false
	if chance>=1.0:
		return true
	return of(stream).randf()<chance

func pick(stream: Stream, options: Array) -> Variant:
	if options.is_empty():
		return null
	return options[of(stream).randi_range(0,options.size()-1)]

## States are stored as decimal strings: a 64-bit generator state does not
## survive the checkpoint codec's plain-number range.
func capture() -> Dictionary:
	var states: Dictionary={}
	for stream in _streams:
		states[str(stream)]=str(of(stream).state)
	return {"seed":master_seed,"states":states}

## JSON has one numeric type, so a stored seed may arrive as a whole float.
static func _whole(value) -> bool:
	return value is int or (value is float and is_finite(value) and floorf(value)==value)

func restore(data: Dictionary) -> bool:
	if not _whole(data.get("seed")) or not data.get("states") is Dictionary:
		return false
	var states: Dictionary=data.states
	if states.size()!=_streams.size():
		return false
	for stream in _streams:
		var key: String=str(stream)
		if not states.has(key) or not states[key] is String or not str(states[key]).is_valid_int():
			return false
	master_seed=int(data.seed)
	for stream in _streams:
		of(stream).state=int(str(states[str(stream)]))
	return true
