extends SceneTree
var failures: int = 0
var assertions: int = 0
var normal: Node
var slow: Node

func _initialize() -> void:
	call_deferred("run")

func expect(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		print("FAIL: ", message)

func pose(speed: float) -> Dictionary:
	return {"alive":true,"hp":100,"shield":0,"facing":1,"moving":true,"horizontal_speed":speed,"grounded":true,"invulnerable":false,"attack_progress":1.0}

func actor() -> Node:
	var node: Node = load("res://scenes/knight_visual.tscn").instantiate()
	node.appearance = load("res://data/hero_v005_appearance.tres")
	root.add_child(node)
	node.reset_pose()
	return node

func index_of(node: Node) -> int:
	if node.unarmed:
		var region: Rect2 = node._unarmed.texture.region
		return int(region.position.y / 96) * node.appearance.stride_columns + int(region.position.x / 128)
	return node.frame

func run() -> void:
	normal = actor()
	slow = actor()
	for unarmed: bool in [false, true]:
		normal.reset_pose();slow.reset_pose()
		normal.unarmed=unarmed;slow.unarmed=unarmed
		for unused: int in range(12):
			normal.present(pose(165), 0.01)
			slow.present(pose(82.5), 0.02)
		expect(index_of(normal)==index_of(slow), "same walking distance yields same foot phase: unarmed="+str(unarmed))
		normal.reset_pose()
		normal.present(pose(165),0)
		var stopped_frame: int=index_of(normal)
		for unused: int in range(25): normal.present(pose(0),0.01)
		expect(index_of(normal)==stopped_frame,"zero displacement cannot cycle feet: unarmed="+str(unarmed))
		normal.reset_pose()
		for unused: int in range(20): normal.present(pose(165),0.01)
		var walking_frame: int=index_of(normal)
		normal.present(pose(321.75),0)
		expect(index_of(normal)==walking_frame,"walk to sprint keeps the supporting foot")
		for unused: int in range(25): normal.present(pose(321.75),0)
		expect(index_of(normal)==walking_frame,"pause freezes gait")
		var left: Dictionary=pose(321.75);left.facing=-1
		normal.present(left,0)
		expect(index_of(normal)==walking_frame,"turnaround keeps gait phase")
		normal.tired_walk=true
		normal.present(pose(69.3),0)
		expect(index_of(normal)==walking_frame,"fatigue keeps gait phase")
		normal.tired_walk=false
	print("Gait presentation: ",assertions," assertions, ",failures," failures")
	normal.queue_free();slow.queue_free()
	await process_frame
	quit(1 if failures else 0)
