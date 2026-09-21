extends RefCounted
## Cosmetic placement uses a separate seed stream, so art never changes resources or saves.
const TEXTURES={"fir":preload("res://art/frontier/variety-v001/fir.png"),"oak":preload("res://art/frontier/variety-v001/oak.png"),"dead_tree":preload("res://art/frontier/variety-v001/dead_tree.png"),"cedar":preload("res://art/frontier/variety-v001/cedar.png"),"log":preload("res://art/frontier/variety-v001/log.png"),"mushrooms":preload("res://art/frontier/variety-v001/mushrooms.png"),"arch":preload("res://art/frontier/variety-v001/arch.png"),"dragon_statue":preload("res://art/frontier/variety-v001/dragon_statue.png"),"basalt":preload("res://art/frontier/variety-v001/basalt.png"),"quartz":preload("res://art/frontier/variety-v001/quartz.png"),"gear":preload("res://art/frontier/variety-v001/gear.png"),"ferns":preload("res://art/frontier/variety-v001/ferns.png")}
static func layout(seed: int,regions: Array) -> Array[Dictionary]:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed^0x31a89f
	var result: Array[Dictionary]=[]
	for index in range(regions.size()):
		var region: Dictionary=regions[index]
		var palettes: Dictionary={
			"forest":[["fir","cedar","oak"],["dead_tree","oak","quartz"],["log","mushrooms","ferns","gear"]],
			"quarry":[["basalt","dead_tree"],["quartz","basalt","dead_tree"],["gear","ferns","mushrooms","log"]],
			"ruins":[["arch","dragon_statue"],["dead_tree","dragon_statue","oak"],["gear","mushrooms","ferns","quartz"]]}
		var palette: Array=palettes[region.kind]
		# One tall focal point per region, an offset middle cluster and a quiet gap.
		var anchor: float=region.x+region.width*rng.randf_range(0.28,0.60)
		for layer in range(3):
			var count:=1 if layer==0 else rng.randi_range(1,3) if layer==1 else rng.randi_range(3,6)
			for i in range(count):
				var kind: String=palette[layer][rng.randi_range(0,palette[layer].size()-1)]
				var height: float=rng.randf_range(210,355) if layer==0 else rng.randf_range(65,170) if layer==1 else rng.randf_range(18,43)
				var x: float=anchor if layer==0 else anchor+105+i*83 if layer==1 else anchor-110+i*62+rng.randf_range(-16,16)
				result.append({"region":index,"x":clampf(x,region.x+24,region.x+region.width-24),"kind":kind,"scale":height/TEXTURES[kind].get_height(),"flip":rng.randf()<0.5,"layer":layer,"y":432})
	result.sort_custom(func(a,b):return a.layer<b.layer)

	return result
static func harvest_texture(kind: String,x: float,seed: int) -> Texture2D:
	var pick:=posmod(int(x)*31+seed,4)
	if kind in ["tree","tree-plain"]:return TEXTURES[["fir","oak","dead_tree","cedar"][pick]]
	if kind=="crystal":return TEXTURES["basalt" if pick<2 else "quartz"]
	return null
## The tallest focal props are wide once scaled, so they cull with extra reach.
const DETAIL_MARGIN := 320.0

static func draw_background(view: Node2D,details: Array,regions: Array) -> void:
	for detail in details:
		if not view._on_screen(detail.x,DETAIL_MARGIN):continue
		var texture: Texture2D=TEXTURES[detail.kind]
		var size: Vector2=texture.get_size()*detail.scale
		var tint: Color=[Color("718995"),Color("a3b2bc"),Color("c0c7b7")][detail.layer]
		tint.a=view._region_reveal(detail.region)
		# A fully hidden region still costs a draw call, so skip it outright.
		if tint.a<=0.0:continue
		view.draw_set_transform(preload("res://presentation/grounded_art.gd").anchor(texture,Vector2(detail.x,detail.y),detail.scale),0,Vector2(-1 if detail.flip else 1,1))
		view.draw_texture_rect(texture,Rect2(Vector2(-size.x/2,-size.y),size),false,tint)
	view.draw_set_transform(Vector2.ZERO)
