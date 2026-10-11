class_name EnemyAppearance
extends Resource
## Presentation-only full-body atlas. Pixels and attack timings stay editable.
@export var atlas: Texture2D
@export var cell: Vector2i
@export var baseline: int
@export var facing: float
@export var walk: PackedInt32Array
@export var windup: PackedInt32Array
@export var strike: PackedInt32Array
@export var hurt: PackedInt32Array
@export var fallen: PackedInt32Array
@export var stride: float
@export var strike_seconds: float
@export var idle_fps: float
@export var hit_height: float
@export var tint: Color

func region(frame: int) -> Rect2:
	return Rect2(Vector2((frame%4)*cell.x,(frame/4)*cell.y),Vector2(cell))

func sample(clip: PackedInt32Array, progress: float) -> int:
	return clip[clampi(int(progress*clip.size()),0,clip.size()-1)]

func valid() -> bool:
	if atlas==null or cell.x<=0 or cell.y<=0 or baseline<=0 or stride<=0 or strike_seconds<=0:return false
	var count: int=int(atlas.get_width()/cell.x)*int(atlas.get_height()/cell.y)
	for clip: PackedInt32Array in [walk,windup,strike,hurt,fallen]:
		if clip.is_empty():return false
		for frame: int in clip:
			if frame<0 or frame>=count:return false
	return absf(facing)==1 and hit_height>0 and idle_fps>0
