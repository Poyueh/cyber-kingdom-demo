class_name AttendantProfile
extends Resource
## Complete-body frames, with deliberate holds rather than uniform ping-pong.
@export var work_frames: PackedInt32Array
@export var work_holds: PackedFloat32Array
@export var greeting_frames: PackedInt32Array
@export var service_frames: PackedInt32Array
@export var alert_frame: int
@export var hand: Vector2
@export var accent: Color
@export var detail: StringName
func valid() -> bool:
 if work_frames.is_empty() or work_frames.size()!=work_holds.size():return false
 if greeting_frames.is_empty() or service_frames.is_empty():return false
 for frame: int in work_frames+greeting_frames+service_frames:
  if frame<0 or frame>3:return false
 for hold: float in work_holds:
  if not is_finite(hold) or hold<=0:return false
 return alert_frame>=0 and alert_frame<4
