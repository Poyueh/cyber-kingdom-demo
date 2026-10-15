extends SceneTree
## Whole-pose handoffs must end on the same neutral silhouette, without rescaling.
var failures: int = 0
var checks: int = 0
func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func frame(texture: Texture2D, index: int, columns: int, size: Vector2i) -> Image:
	return texture.get_image().get_region(Rect2i(Vector2i(index % columns, index / columns) * size, size))
func placed(source: Image, size: Vector2i, offset: Vector2i) -> Image:
	var target: Image = Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	target.blit_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),offset)
	return target
func same(a: Image,b: Image) -> bool:
	a.convert(Image.FORMAT_RGBA8); b.convert(Image.FORMAT_RGBA8)
	return a.get_size()==b.get_size() and a.get_data()==b.get_data()
func _initialize() -> void:
	var appearance: Resource = load("res://data/hero_v005_appearance.tres")
	var idle: Image = appearance.frames.get_frame_texture(&"idle",0).get_image()
	var large: Image = placed(idle,Vector2i(160,128),Vector2i(16,32))
	for texture: Texture2D in [appearance.combo.planted_atlas,appearance.combo.moving_atlas]:
		for row: int in range(3):
			for index: int in [0,11]:
				expect(same(frame(texture,row*12+index,12,Vector2i(160,128)),large),"attack entry/recovery returns to canonical idle: %d/%d" % [row,index])
	expect(same(appearance.frames.get_frame_texture(&"hurt",3).get_image(),idle),"armed hurt recovers to idle")
	var unarmed: Image = frame(appearance.unarmed_idle,0,4,Vector2i(128,96))
	expect(same(frame(appearance.unarmed_hurt,3,4,Vector2i(128,96)),unarmed),"unarmed hurt recovers to idle")
	expect(same(frame(appearance.ceremony,7,4,Vector2i(160,128)),placed(idle,Vector2i(160,128),Vector2i(16,16))),"drawing sword ends in the armed idle pose")
	for index: int in [3,7]:
		expect(same(frame(appearance.rest,index,4,Vector2i(160,128)),placed(unarmed if index==3 else idle,Vector2i(160,128),Vector2i(16,16))),"standing from rest returns to neutral")
	print("Knight continuity: %d assertions, %d failures" % [checks,failures])
	quit(1 if failures else 0)
