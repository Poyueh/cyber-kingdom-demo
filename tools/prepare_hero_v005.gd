extends SceneTree
## Offline import only: isolate complete generated poses and pack native pixel atlases.
## No limb transforms, repainting, or runtime resampling. Originals remain untouched.
const SOURCE: String="res://art/concepts/hero-v005/sources/"
const OUT: String="res://art/characters/hero-v005/"
const ALPHA: int=180
var sockets: Dictionary={}
var metrics: Dictionary={}
var source_metrics: Dictionary={}
var cache: Dictionary={}
var failures: int=0
class Cut extends RefCounted:
	var pixels: PackedInt32Array=PackedInt32Array()
	var rect: Rect2i

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	call_deferred("build")

func cuts(name: String, count: int, rows: int) -> Array[Image]:
	if cache.has(name):return cache[name]
	var image: Image=Image.load_from_file(SOURCE+name+".png")
	image.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray=image.get_data()
	var w: int=image.get_width();var h: int=image.get_height()
	var visited: PackedByteArray=PackedByteArray();visited.resize(w*h)
	var parts: Array[Cut]=[]
	for start: int in range(w*h):
		if visited[start] or data[start*4+3]<ALPHA:continue
		var part: Cut=Cut.new()
		var todo: PackedInt32Array=PackedInt32Array([start]);visited[start]=1
		var cursor: int=0;var lo: Vector2i=Vector2i(start%w,start/w);var hi: Vector2i=lo
		while cursor<todo.size():
			var pixel: int=todo[cursor];cursor+=1;part.pixels.append(pixel)
			var x: int=pixel%w;var y: int=pixel/w
			lo.x=mini(lo.x,x);lo.y=mini(lo.y,y);hi.x=maxi(hi.x,x);hi.y=maxi(hi.y,y)
			for dy: int in range(-1,2):
				for dx: int in range(-1,2):
					var nx: int=x+dx;var ny: int=y+dy
					if nx<0 or nx>=w or ny<0 or ny>=h:continue
					var other: int=ny*w+nx
					if not visited[other] and data[other*4+3]>=ALPHA:
						visited[other]=1;todo.append(other)
		part.rect=Rect2i(lo,hi-lo+Vector2i.ONE)
		if part.pixels.size()>24:parts.append(part)
	parts.sort_custom(func(a: Cut,b: Cut)->bool:return a.pixels.size()>b.pixels.size())
	assert(parts.size()>=count,"Too few complete drawings: "+name)
	var selected: Array[Cut]=[];selected.assign(parts.slice(0,count))
	selected.sort_custom(func(a: Cut,b: Cut)->bool:return a.rect.end.y<b.rect.end.y)
	var ordered: Array[Cut]=[]
	for row: int in range(rows):
		var line: Array[Cut]=[];line.assign(selected.slice(row*4,row*4+4))
		line.sort_custom(func(a: Cut,b: Cut)->bool:return a.rect.position.x<b.rect.position.x)
		ordered.append_array(line)
	# The sword remains separate from the hand in the opening extraction drawing.
	if name=="ceremony":
		for extra: Cut in parts.slice(count):
			if extra.rect.get_center().x<w/4 and extra.rect.end.y<h/2 and extra.pixels.size()>300:
				ordered[0].pixels.append_array(extra.pixels)
				ordered[0].rect=ordered[0].rect.merge(extra.rect)
	var result: Array[Image]=[];var boxes: Array[Rect2i]=[]
	for part: Cut in ordered:
		var tile: Image=Image.create(part.rect.size.x,part.rect.size.y,false,Image.FORMAT_RGBA8)
		for pixel: int in part.pixels:
			var color: Color=image.get_pixel(pixel%w,pixel/w);color.a=1
			tile.set_pixel(pixel%w-part.rect.position.x,pixel/w-part.rect.position.y,color)
		result.append(tile);boxes.append(part.rect)
	source_metrics[name]={"count":count,"boxes":boxes,"source_size":image.get_size()}
	cache[name]=result;print("Isolated ",name," ",result.size())
	return result

func feet_center(tile: Image) -> float:
	var xs: Array[int]=[]
	for y: int in range(int(tile.get_height()*0.86),tile.get_height()):
		for x: int in range(tile.get_width()):
			var c: Color=tile.get_pixel(x,y)
			if c.a>0 and c.g>c.r*0.72 and c.g<c.r*1.2 and c.b<c.r*1.3:xs.append(x)
	if xs.is_empty():return tile.get_width()*0.5
	xs.sort();return xs[xs.size()/2]

func face_center(tile: Image) -> float:
	var xs: Array[int]=[]
	for y: int in range(int(tile.get_height()*0.28)):
		for x: int in range(tile.get_width()):
			var c: Color=tile.get_pixel(x,y)
			if c.a>0 and c.g>0.4 and c.b>0.4 and c.g>c.r*1.18 and c.b>c.r*1.2:xs.append(x)
	if xs.is_empty():return feet_center(tile)+8
	xs.sort();return xs[xs.size()/2]

func native(tile: Image, factor: float, size: Vector2i=Vector2i(128,96), ground: int=81, hop: int=0, anchor: float=-1) -> Image:
	var pivot: float=feet_center(tile) if anchor<0 else anchor
	var out: Image=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	var copy: Image=tile.duplicate()
	copy.resize(roundi(tile.get_width()*factor),roundi(tile.get_height()*factor),Image.INTERPOLATE_NEAREST)
	var pos: Vector2i=Vector2i(roundi(size.x*0.5+(8 if anchor<0 else 0)-pivot*factor),ground-copy.get_height()-hop)
	if pos.x<0 or pos.y<0 or pos.x+copy.get_width()>size.x:
		failures+=1;push_error("Native pose exceeds canvas: %s %s %s"%[pos,copy.get_size(),size])
		return out
	out.blit_rect(copy,Rect2i(Vector2i.ZERO,copy.get_size()),pos)
	return out

func median_height(tiles: Array[Image]) -> float:
	var heights: Array[int]=[]
	for tile: Image in tiles:heights.append(tile.get_height())
	heights.sort();return float(heights[heights.size()/2])

func shoulder(frame: Image, name: String, index: int) -> Vector2:
	var rect: Rect2i=frame.get_used_rect()
	var target: Vector2=Vector2(frame.get_width()*0.5+7,rect.position.y+8)
	if name.begins_with("planted") or name.begins_with("advancing"):
		target.y=rect.end.y-50
	if name.begins_with("mounted"):target.y=rect.end.y-70
	if name.begins_with("death") and index>=2:return Vector2(frame.get_width()/2+5,rect.end.y-7)
	var best: Vector2=target;var distance: float=INF
	for y: int in range(rect.position.y,mini(rect.end.y,roundi(target.y)+12)):
		for x: int in range(maxi(0,roundi(target.x)-20),mini(frame.get_width(),roundi(target.x)+20)):
			var c: Color=frame.get_pixel(x,y)
			if c.a==0 or c.g<0.42 or c.b<0.42 or c.g<c.r*1.12 or c.b<c.r*1.16:continue
			var d: float=Vector2(x,y).distance_squared_to(target)
			if d<distance:best=Vector2(x,y);distance=d
	return (best+Vector2(-7,8)).round()

func pack(drawings: Array[Image], columns: int, name: String) -> void:
	var size: Vector2i=drawings[0].get_size()
	var atlas: Image=Image.create(size.x*columns,size.y*ceili(float(drawings.size())/columns),false,Image.FORMAT_RGBA8)
	var points: Array[Vector2]=[];var bounds: Array[Rect2i]=[]
	for i: int in range(drawings.size()):
		var rect: Rect2i=drawings[i].get_used_rect();assert(rect.has_area())
		atlas.blit_rect(drawings[i],Rect2i(Vector2i.ZERO,size),Vector2i(i%columns*size.x,i/columns*size.y))
		points.append(shoulder(drawings[i],name,i));bounds.append(rect)
	atlas.save_png(OUT+name+".png")
	sockets[name+".png"]=points
	metrics[name]={"frames":drawings.size(),"columns":columns,"cell":size,"bounds":bounds}

func build() -> void:
	for action: String in ["run","sprint","walk"]:
		var armed: Array[Image]=cuts(action,12,3)
		var factor: float=(57.0 if action=="run" else 55.0 if action=="sprint" else 60.0)/median_height(armed)
		for suffix: String in ["","-unarmed"]:
			var drawings: Array[Image]=[]
			var source: Array[Image]=armed if suffix.is_empty() else cuts(action+suffix,12,3)
			for i: int in range(12):
				var hop: int=([0,0,1,2,2,1,0,0,1,2,2,1][i] if action!="walk" else 0)
				drawings.append(native(source[i],factor,Vector2i(128,96),81,hop,face_center(source[i])-9.0/factor))
			pack(drawings,4,action+suffix)
	var support: Array[Image]=cuts("support",16,4)
	var factor: float=60.0/median_height(support.slice(0,4))
	var resting: Array[Image]=[]
	for suffix: String in ["-unarmed",""]:
		var source: Array[Image]=support if suffix.is_empty() else cuts("support-unarmed",16,4)
		var drawings: Array[Image]=[]
		for tile: Image in source:drawings.append(native(tile,factor))
		pack(drawings.slice(0,4),4,"idle"+suffix)
		pack(drawings.slice(4,8),4,"hurt"+suffix)
		pack(drawings.slice(8,12),4,"death"+suffix)
		for i: int in range(12,16):resting.append(native(source[i],factor,Vector2i(160,128),97))
	pack(resting,4,"rest")
	var ceremony: Array[Image]=cuts("ceremony",8,2)
	var poses: Array[Image]=[]
	for tile: Image in ceremony:poses.append(native(tile,60.0/ceremony[0].get_height(),Vector2i(160,128),97))
	pack(poses,4,"ceremony")
	var cavalry: Array[Image]=cuts("mounted",16,4)
	factor=83.0/median_height(cavalry.slice(0,8))
	for suffix: String in ["","-unarmed"]:
		poses=[]
		var source: Array[Image]=cavalry if suffix.is_empty() else cuts("mounted-unarmed",16,4)
		for tile: Image in source:poses.append(native(tile,factor,Vector2i(160,128),97))
		pack(poses,8,"mounted"+suffix)
	for suffix: String in ["","-advance"]:
		poses=[]
		for action: String in ["slash","rising","heavy"]:
			var source: Array[Image]=cuts(action+suffix,12,3)
			factor=60.0/source[0].get_height()
			for tile: Image in source:poses.append(native(tile,factor,Vector2i(160,128),113))
		pack(poses,12,"planted" if suffix.is_empty() else "advancing")
	var air: Array[Image]=cuts("air",8,2)
	factor=52.0/air[0].get_height()
	poses=[]
	for tile: Image in air:poses.append(native(tile,factor))
	pack(poses.slice(0,4),4,"jump");pack(poses.slice(4,8),4,"jump-unarmed")
	var file: FileAccess=FileAccess.open(OUT+"sockets.json",FileAccess.WRITE)
	var json_points: Dictionary={}
	for key: String in sockets:
		json_points[key]=[]
		for point: Vector2 in sockets[key]:json_points[key].append([point.x,point.y])
	file.store_string(JSON.stringify(json_points,"\t"));file.close()
	file=FileAccess.open(OUT+"metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify({"native":metrics,"sources":source_metrics},"\t"));file.close()
	print("Native hero build failures: ",failures);quit(1 if failures else 0)
