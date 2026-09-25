extends RefCounted
## Stateless schedule: a full battlefield delays reinforcements, never deletes them.
var _modern: bool
var _first: int
var _growth: int
var _limit: int
var concurrent_limit: int

func _init(config: Dictionary) -> void:
	_modern = config.has("night_first")
	if _modern:
		_first = int(config.night_first)
		_growth = int(config.night_growth)
		_limit = int(config.night_limit)
		concurrent_limit = int(config.night_concurrent)
	else:
		# Compatibility for already saved journeys, which have no pressure profile.
		concurrent_limit = 100 # Existing save admission ceiling, including gate wardens.

func count_for(day: int) -> int:
	if not _modern: return mini(12,2+day)
	return mini(_limit,_first+maxi(0,day-1)*_growth)
