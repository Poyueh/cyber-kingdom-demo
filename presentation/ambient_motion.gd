extends RefCounted
## All motion takes simulation time: pausing never leaves decorative loops running.
static func prop(canvas: Node2D, texture: Texture2D, kind: String, at: Vector2, scale: float, tint: Color, time: float) -> void:
	at=preload("res://presentation/grounded_art.gd").anchor(texture,at,scale)
	var size := texture.get_size()*scale
	var phase := time*1.8+at.x*0.019
	if kind in ["tree","tree-plain","berries","herbs","crops","campfire"]:
		# Horizontal strips bend foliage/flame while the feet/root stay planted.
		for row in range(0,texture.get_height(),4):
			var height := mini(4,texture.get_height()-row)
			var height_ratio := 1.0-float(row)/texture.get_height()
			var wind := sin(phase+height_ratio*1.1)*3.0
			if kind=="campfire": wind=sin(time*13+row*0.8)*2.2
			var offset := roundf(wind*height_ratio*height_ratio)*scale
			var lift: float=roundf(sin(time*9.0+row*0.11)*8.0*height_ratio*height_ratio)*scale if kind=="campfire" else 0.0
			canvas.draw_texture_rect_region(texture,Rect2(at-Vector2(size.x*0.5,size.y)+Vector2(offset,row*scale+lift),Vector2(size.x,height*scale*(1.5 if kind=="campfire" and height_ratio>0.3 else 1.0))),Rect2(0,row,texture.get_width(),height),tint)
	else:
		if kind=="deer": size.y*=1.0+sin(phase*1.5)*0.012
		canvas.draw_texture_rect(texture,Rect2(at-Vector2(size.x*0.5,size.y),size),false,tint)
	if tint.a<0.6: return
	if kind in ["campfire","forge"]:
		for index in range(10 if kind=="campfire" else 5):
			var rise := fposmod(time*0.85+index*0.17,1.0)
			var point := at+Vector2(sin(index*4.1+time*1.2)*12,-12-rise*65)*scale
			canvas.draw_rect(Rect2(point.round(),Vector2.ONE*2),Color(1,0.62+rise*0.2,0.25,(1-rise)*0.85))
	elif kind in ["cache","crystal","beacon","outpost","hall-1","hall-2","hall-3","workshop","armory","wall","stone","plot","stump"]:
		var pulse := pow(maxf(0,sin(time*2.2+at.x*0.07)),6)
		var point := at+Vector2(size.x*0.12,-size.y*0.63)
		var color := Color(0.55,0.96,0.87,pulse*0.8)
		canvas.draw_line(point-Vector2(3,0),point+Vector2(3,0),color,1)
		canvas.draw_line(point-Vector2(0,3),point+Vector2(0,3),color,1)

static func crystal(canvas: Node2D, gem: Dictionary, radius: float, time: float) -> void:
	var phase: float = time*3.8+gem.id*1.71
	var at := Vector2(gem.x,gem.y-14-sin(phase)*2.5).round()
	var color := Color(0.21,0.85,0.78,0.08+0.04*sin(phase))
	canvas.draw_circle(at,radius*1.9,color)
	canvas.draw_line(Vector2(gem.x-radius*0.6,gem.y+1),Vector2(gem.x+radius*0.6,gem.y+1),Color(0.01,0.06,0.08,0.35),2)
	if gem.attracted:
		for index in range(1,4):
			canvas.draw_circle(at+Vector2(-gem.get("trail_x",0.0),-gem.get("trail_y",0.0))*index*5,radius*0.3,Color(0.45,1,0.87,0.24/float(index)))
	var width := radius*(0.62+sin(phase*0.7)*0.08)
	var top := at+Vector2(0,-radius)
	var right := at+Vector2(width,0)
	var bottom := at+Vector2(0,radius)
	var left := at-Vector2(width,0)
	canvas.draw_colored_polygon(PackedVector2Array([top,right,bottom,left]),Color("245764"))
	canvas.draw_colored_polygon(PackedVector2Array([top,right,bottom,at]),Color("39b7b2"))
	canvas.draw_colored_polygon(PackedVector2Array([top,at,bottom,left]),Color("91f4ce"))
	canvas.draw_polyline(PackedVector2Array([top,right,bottom,left,top]),Color("d5ffe9"),1)
	canvas.draw_line(top+Vector2(0,3),left+Vector2(2,0),Color.WHITE,1)
	if sin(phase)>0.8:
		canvas.draw_line(at+Vector2(radius, -radius-2),at+Vector2(radius,-radius+2),Color("d5ffe9"),1)
		canvas.draw_line(at+Vector2(radius-2,-radius),at+Vector2(radius+2,-radius),Color("d5ffe9"),1)
