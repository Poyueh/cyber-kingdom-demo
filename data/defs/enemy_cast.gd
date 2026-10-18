class_name EnemyCast
extends Resource
## Paths keep unrelated worlds out of memory. Presentation loads once per world.
@export var impact_kick: float
@export var impact_seconds: float
@export var impact_distance: float
@export var grunt: EnemyAppearance
@export var carry: EnemyAppearance
@export_file("*.tres") var guardians: Array[String]
@export_file("*.tres") var dragons: Array[String]

func valid() -> bool:
	if impact_kick<0 or impact_seconds<=0 or impact_distance<=0:return false
	if grunt==null or carry==null or guardians.size() not in [1,7] or dragons.size()!=guardians.size():return false
	if not grunt.valid() or not carry.valid():return false
	for group: Array[String] in [guardians,dragons]:
		for path: String in group:
			if not path.begins_with("res://data/enemy_appearance/") or not path.ends_with(".tres"):return false
	return true
