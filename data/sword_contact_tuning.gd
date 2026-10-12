extends Resource
## Forward/rear body extents measured in the enemy's authored facing direction.
@export var ordinary: Vector2=Vector2(40,30)
@export var guardian: Vector2=Vector2(64,44)
@export var dragon: Vector2=Vector2(168,168)
@export_range(0,24,1) var finisher_extension: float=8.0

func apply_to(contact: RefCounted) -> void:
	for bounds: Vector2 in [ordinary,guardian,dragon]:
		assert(bounds.is_finite() and bounds.x>=0 and bounds.y>=0)
	assert(is_finite(finisher_extension) and finisher_extension>=0)
	contact.configure(ordinary,guardian,dragon,finisher_extension)
