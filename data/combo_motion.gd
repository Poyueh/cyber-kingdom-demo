extends Resource
## Art and frame timing only; damage and combo state remain in domain.
@export var planted_atlas: Texture2D
@export var moving_atlas: Texture2D
@export_range(1,8,1) var moving_gait_rows: int = 8
@export var slash_weights := PackedFloat32Array([0.12,0.12,0.08,0.08,0.16,0.18,0.14,0.12])
@export var rising_weights := PackedFloat32Array([0.10,0.10,0.05,0.15,0.12,0.13,0.15,0.20])
@export var heavy_weights := PackedFloat32Array([0.12,0.12,0.10,0.06,0.16,0.18,0.14,0.12])

func frame_at(step: int, progress: float) -> int:
	var weights: PackedFloat32Array = rising_weights if step==2 else (heavy_weights if step==3 else slash_weights)
	var total := 0.0
	for weight in weights: total += maxf(0.001,weight)
	var remaining := clampf(progress,0.0,1.0)*total
	for index in range(weights.size()):
		remaining -= maxf(0.001,weights[index])
		if remaining<0.0: return mini(index,7)
	return 7
