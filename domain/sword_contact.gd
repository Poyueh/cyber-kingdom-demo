extends RefCounted
## Immutable composition-time geometry; never stored as journey progression.
var configured: bool=false
var ordinary: Vector2=Vector2.ZERO
var guardian: Vector2=Vector2.ZERO
var dragon: Vector2=Vector2(70,70) # Existing prototype contact until configured.
var finisher_extension: float=0.0

func configure(body: Vector2, elite: Vector2, boss: Vector2, heavy: float) -> void:
	ordinary=body;guardian=elite;dragon=boss;finisher_extension=heavy;configured=true

func distance(center: float, kind: String, direction: float, facing: int, step: int) -> float:
	# Keep the centre's side before shrinking distance: a rear body must not
	# become a signed zero and accidentally count as a forward target.
	if center*facing<0:return center
	var shape: Vector2=dragon if kind=="dragon" else guardian if kind in ["warden","roamer"] else ordinary
	var edge: float=shape.x if center*direction<0 else shape.y
	var extension: float=finisher_extension if step==3 else 0.0
	return signf(center)*maxf(0.0,absf(center)-edge-extension)
