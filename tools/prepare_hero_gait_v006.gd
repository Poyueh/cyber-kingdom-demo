extends "res://tools/prepare_hero_v005.gd"
## Offline whole-pose packing. One scale and one pelvis anchor for all four clips.
const GAIT_SOURCE: String = "res://art/concepts/hero-gait-v006/sources/"
const GAIT_OUT: String = "res://art/characters/hero-gait-v006/"
const COLUMNS: int = 8
const COUNT: int = 16
const PELVIS_X: float = 0.60
const RUN_LIFT: Array[int] = [0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 1, 2, 2, 1]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(GAIT_OUT)
	call_deferred("build")

func build() -> void:
	var walk: Array[Image] = cuts("walk", COUNT, 2, COLUMNS, GAIT_SOURCE)
	var factor: float = 60.0 / median_height(walk)
	for name: String in ["walk", "walk-unarmed", "sprint", "sprint-unarmed"]:
		var source: Array[Image] = cuts(name, COUNT, 2, COLUMNS, GAIT_SOURCE)
		var width: float = source_metrics[name].source_size.x
		var boxes: Array = source_metrics[name].boxes
		var poses: Array[Image] = []
		for index: int in range(COUNT):
			# Keep the same hip coordinate inside each source cell; never follow the foot.
			var source_anchor: float = (index % COLUMNS + PELVIS_X) * width / COLUMNS
			var anchor: float = source_anchor - boxes[index].position.x
			var lift: int = RUN_LIFT[index] if name.begins_with("sprint") else 0
			poses.append(native(source[index], factor, Vector2i(128, 96), 81, lift, anchor))
		pack(poses, COLUMNS, "gait-" + name, GAIT_OUT)
		metrics["gait-" + name]["scale"] = factor
	var points: Dictionary = {}
	for key: String in sockets:
		points[key] = []
		for point: Vector2 in sockets[key]: points[key].append([point.x, point.y])
	var file: FileAccess = FileAccess.open(GAIT_OUT + "sockets.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(points, "\t"))
	file.close()
	file = FileAccess.open(GAIT_OUT + "metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"native":metrics,"sources":source_metrics,"shared_scale":factor,"pelvis_fraction":PELVIS_X}, "\t"))
	file.close()
	print("Gait packing failures: ", failures)
	quit(1 if failures else 0)
