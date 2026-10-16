extends "res://tools/prepare_hero_v005.gd"
## Whole-pose import: preserve anatomical proportions; no body-part deformation.
const INPUT: String = "res://art/concepts/hero-v011/sources/"
const OUTPUT: String = "res://art/characters/hero-v011/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	call_deferred("build")

func build() -> void:
	var support: Array[Image] = cuts("support", 16, 4, 4, INPUT)
	var factor: float = 60.0 / median_height(support.slice(0,4))
	var rest: Array[Image] = []
	var neutral: Image = native(support[0],factor,Vector2i(160,128),113,0,face_center(support[0])-9.0/factor)
	for suffix: String in ["-unarmed", ""]:
		var source: Array[Image] = support if suffix.is_empty() else cuts("support-unarmed",16,4,4,INPUT)
		var poses: Array[Image] = []
		for index: int in range(source.size()):
			var tile: Image=source[index]
			poses.append(native(tile,factor,Vector2i(128,96),81,0,face_center(tile)-9.0/factor) if index<4 else native(tile,factor,Vector2i(128,96),81,0,tile.get_width()*0.5) if index in [10,11] else native(tile,factor))
		pack(poses.slice(0,4),4,"idle"+suffix,OUTPUT)
		poses[7] = poses[0].duplicate()
		pack(poses.slice(4,8),4,"hurt"+suffix,OUTPUT)
		pack(poses.slice(8,12),4,"death"+suffix,OUTPUT)
		for index: int in range(12,16): rest.append(native(source[index],60.0/source[15].get_height(),Vector2i(160,128),97))
		rest[rest.size()-1] = native(source[0],factor,Vector2i(160,128),97,0,face_center(source[0])-9.0/factor)
	pack(rest,4,"rest",OUTPUT)
	var source: Array[Image] = cuts("ceremony",8,2,4,INPUT)
	factor = 60.0/source[0].get_height()
	var poses: Array[Image] = []
	for tile: Image in source: poses.append(native(tile,factor,Vector2i(160,128),97))
	var idle_factor: float=60.0/median_height(support.slice(0,4))
	poses[7] = native(support[0],idle_factor,Vector2i(160,128),97,0,face_center(support[0])-9.0/idle_factor)
	pack(poses,4,"ceremony",OUTPUT)
	for suffix: String in ["", "-advance"]:
		poses=[]
		for action: String in ["slash","rising","heavy"]:
			source=cuts(action+suffix,12,3,4,INPUT)
			factor=60.0/source[0].get_height()
			for index: int in range(source.size()):
				poses.append(neutral.duplicate() if index in [0,11] else native(source[index],factor,Vector2i(160,128),113))
		pack(poses,12,"planted" if suffix.is_empty() else "advancing",OUTPUT)
	var cavalry: Array[Image] = cuts("mounted",16,4,4,INPUT)
	factor=83.0/median_height(cavalry.slice(0,8))
	for suffix: String in ["", "-unarmed"]:
		source=cavalry if suffix.is_empty() else cuts("mounted-unarmed",16,4,4,INPUT)
		poses=[]
		for tile: Image in source: poses.append(native(tile,factor,Vector2i(160,128),97))
		pack(poses,8,"mounted"+suffix,OUTPUT)
	source=cuts("air",8,2,4,INPUT)
	factor=52.0/source[0].get_height()
	poses=[]
	for index: int in range(source.size()):
			var tile: Image=source[index]
			poses.append(native(tile,factor,Vector2i(128,96),81,0,face_center(tile)-9.0/factor) if index<4 else native(tile,factor,Vector2i(128,96),81,0,tile.get_width()*0.5) if index in [10,11] else native(tile,factor))
	pack(poses.slice(0,4),4,"jump",OUTPUT)
	pack(poses.slice(4,8),4,"jump-unarmed",OUTPUT)
	var points: Dictionary = {}
	for key: String in sockets:
		points[key]=[]
		for point: Vector2 in sockets[key]: points[key].append([point.x,point.y])
	var file: FileAccess = FileAccess.open(OUTPUT+"sockets.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(points,"\t"));file.close()
	file=FileAccess.open(OUTPUT+"metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"native":metrics,"sources":source_metrics},"\t"));file.close()
	print("Hero v011 packing failures: ",failures)
	quit(1 if failures else 0)
