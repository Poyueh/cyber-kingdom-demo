extends SceneTree
## Mechanical sprite registration only. All subject artwork comes from imagegen.
const INPUT: String="res://art/concepts/motorcycle-v001/"
const OUTPUT: String="res://art/characters/motorcycle-v001/"
const CELL: Vector2i=Vector2i(160,128)
const RIDER_SCALE: float=0.19
func hard_alpha(image: Image) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	var bytes: PackedByteArray=image.get_data()
	for index: int in range(3,bytes.size(),4):
		bytes[index]=255 if bytes[index]>=160 else 0
	return Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes)
func pieces(image: Image) -> Array[Dictionary]:
	var bytes: PackedByteArray=image.get_data()
	var width: int=image.get_width()
	var height: int=image.get_height()
	var visited: PackedByteArray=[]
	visited.resize(width*height)
	var result: Array[Dictionary]=[]
	for at: int in range(width*height):
		if visited[at] or bytes[at*4+3]==0:continue
		var stack: PackedInt32Array=[at]
		var pixels: PackedInt32Array=[]
		visited[at]=1
		var left: int=width
		var right: int=0
		var top: int=height
		var bottom: int=0
		while not stack.is_empty():
			var point: int=stack[stack.size()-1]
			stack.resize(stack.size()-1)
			pixels.append(point)
			var x: int=point%width
			var y: int=point/width
			left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
			for direction: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var nx: int=x+direction.x
				var ny: int=y+direction.y
				var next: int=ny*width+nx
				if nx<0 or nx>=width or ny<0 or ny>=height:continue
				if visited[next] or bytes[next*4+3]==0:continue
				visited[next]=1;stack.append(next)
		if pixels.size()<5000:continue
		var box: Rect2i=Rect2i(left,top,right-left+1,bottom-top+1)
		var cut: Image=Image.create_empty(box.size.x,box.size.y,false,Image.FORMAT_RGBA8)
		for pixel: int in pixels:
			var x: int=pixel%width
			var y: int=pixel/width
			cut.set_pixel(x-left,y-top,image.get_pixel(x,y))
		result.append({"box":box,"image":cut})
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var row_a: int=int(a.box.end.y/500)
		var row_b: int=int(b.box.end.y/500)
		return a.box.position.x<b.box.position.x if row_a==row_b else row_a<row_b)
	return result
func _initialize() -> void:
	var vehicle: Image=hard_alpha(Image.load_from_file(INPUT+"vehicle.png"))
	var bike: Image=vehicle.get_region(vehicle.get_used_rect())
	print("Vehicle bounds ",vehicle.get_used_rect())
	bike.resize(136,roundi(bike.get_height()*136.0/bike.get_width()),Image.INTERPOLATE_NEAREST)
	var chassis: Image=Image.create_empty(CELL.x,CELL.y,false,Image.FORMAT_RGBA8)
	chassis.blit_rect(bike,Rect2i(Vector2i.ZERO,bike.get_size()),Vector2i(12,96-bike.get_height()))
	chassis.save_png(OUTPUT+"parked.png")
	var riders: Array[Dictionary]=pieces(hard_alpha(Image.load_from_file(INPUT+"riders.png")))
	for rider: Dictionary in riders:print("Rider bounds ",rider.box)
	if riders.size()!=8:
		push_error("Expected eight complete independent rider silhouettes");quit(1);return
	# Hips, not bounding boxes, register the eight authored action poses.
	var hips: Array[Vector2i]=[Vector2i(208,365),Vector2i(692,365),Vector2i(1137,365),Vector2i(1556,365),Vector2i(208,719),Vector2i(687,719),Vector2i(1116,719),Vector2i(1532,719)]
	var frames: Array[Image]=[]
	for i: int in range(8):
		var cut: Image=riders[i].image
		var hip: Vector2i=hips[i]-Vector2i(riders[i].box.position)
		cut.resize(roundi(cut.get_width()*RIDER_SCALE),roundi(cut.get_height()*RIDER_SCALE),Image.INTERPOLATE_NEAREST)
		var frame: Image=chassis.duplicate()
		frame.blend_rect(cut,Rect2i(Vector2i.ZERO,cut.get_size()),Vector2i(64,67)-Vector2i(roundi(hip.x*RIDER_SCALE),roundi(hip.y*RIDER_SCALE)))
		frames.append(frame)
	var mapping: Array[int]=[1,1,1,1,1,1,1,1,2,3,4,5,0,0,6,7]
	for armed: bool in [true,false]:
		var atlas: Image=Image.create_empty(CELL.x*8,CELL.y*2,false,Image.FORMAT_RGBA8)
		for i: int in range(16):
			atlas.blit_rect(frames[mapping[i] if armed else 7],Rect2i(Vector2i.ZERO,CELL),Vector2i(i%8*CELL.x,i/8*CELL.y))
		atlas.save_png(OUTPUT+("mounted.png" if armed else "mounted-unarmed.png"))
	# Environmental source contains two isolated components; keep the drawing unchanged.
	var structures: Array[Dictionary]=pieces(hard_alpha(Image.load_from_file(INPUT+"workshop.png")))
	for structure: Dictionary in structures:print("Structure bounds ",structure.box)
	# The workshop is a single connected timber/stone silhouette.
	for i: int in range(structures.size()):
		var image: Image=structures[i].image
		var width: int=172 if i==0 else 216
		image.resize(width,roundi(image.get_height()*float(width)/image.get_width()),Image.INTERPOLATE_NEAREST)
		image.save_png("res://art/structures/motorcycle-v001/"+("cradle.png" if i==0 else "garage.png"))
	quit()
