extends "res://presentation/settlement_view.gd"
const Scenery = preload("res://presentation/refuge_scenery.gd")
## Region names and outpost plots are centred labels, so they need a wider reach.
const LABEL_MARGIN := 260.0
@export var art: Resource = preload("res://data/frontier_art.tres")

func _prop(name: String, at: Vector2, scale: float = 1.0, tint := Color.WHITE) -> void:
	var texture: Texture2D = art.props[name]
	var size := texture.get_size()*scale
	draw_texture_rect(texture,Rect2(at-Vector2(size.x*0.5,size.y),size),false,tint)

func _draw() -> void:
	if _sim == null or _font == null: return
	var map = _sim.frontier
	_refresh_span()
	var left: float = _span.x
	# Frame the complete skyline above the real floor, independently of camera zoom.
	_draw_sky(_background_rect())
	Scenery.forest(self,art.forest_layer,_background_rect(),art.forest_scroll)
	# Draw beyond both viewport edges, even during camera smoothing at world limits.
	preload("res://presentation/scenery_tiles.gd").draw(self,art.ground,_background_rect(),430)
	_draw_atmosphere(left)
	for region in map.regions:
		if not region.discovered:
			_draw_unexplored(region)
		elif _on_screen(region.x+region.width*0.5,LABEL_MARGIN):
			var name: String = {"forest":tr("龍晶林 · 標記居民伐木"),"quarry":tr("晶脈 · 標記居民採礦"),"ruins":tr("舊王朝遺跡 · 回收廢料")}[region.kind]
			_text(name,region.x+region.width*0.5,143,Color("d6d6b5"),16)
	for resource in map.nodes:
		if not _on_screen(resource.x):continue
		_world_alpha=_region_reveal(resource.region)
		if _world_alpha>0:_resource(resource)
	for animal in map.animals:
		if not _on_screen(animal.x):continue
		_world_alpha=_region_reveal(animal.region)
		if animal.alive and _world_alpha>0:_prop("deer",Vector2(animal.x,430),0.75)
	_world_alpha=1.0
	for region in map.regions:
		if not region.outpost_ready: continue
		if not _on_screen(region.outpost_x,LABEL_MARGIN):continue
		if not _outpost_visible(region):continue
		var at := Vector2(region.outpost_x,430)
		_prop("outpost",at,0.8,Color(1,1,1,1.0 if region.outpost_built else 0.35))
		if region.outpost_pending:
			draw_line(at+Vector2(-47,0),at+Vector2(-47,-94),Color("c3a171"),3)
			draw_line(at+Vector2(47,0),at+Vector2(47,-94),Color("c3a171"),3)
			_text(tr("施工 %d%%") % int(100*region.outpost_progress/map.outpost_seconds),at.x,315,Color("edd19d"),13)
		else: _text(tr("拓荒站") if region.outpost_built else tr("已清理 · 可拓建"),at.x,312,Color("b6dfd0"),13)
	super._draw()

var _world_alpha:=1.0
func _region_reveal(index: int) -> float:
	return 1.0 if index<0 or _sim.frontier.regions[index].discovered else 0.0

func _draw_sky(bounds: Rect2) -> void:
	draw_texture_rect(art.woodland,bounds,false)

func _background_rect() -> Rect2:
	var inverse:=get_viewport().get_canvas_transform().affine_inverse()
	var top_left:=inverse*Vector2.ZERO
	var bottom_right:=inverse*get_viewport_rect().size
	return Rect2(top_left,Vector2(bottom_right.x-top_left.x,430-top_left.y))

func _draw_structures() -> void:
	var world = _sim.world
	var map = _sim.frontier
	_prop("hall-%d" % map.city_level,Vector2(world.sites.hall,430))
	_text(tr("王城") if map.city_level==3 else tr("聚落 %d/3") % map.city_level,world.sites.hall,230 if map.city_level==3 else 279,Color("ead5aa"),16)
	for site in ["workshop","armory"]:
		var x: float = world.sites[site]
		_prop(site,Vector2(x,430))
		_text(tr("工坊 / 工程器具") if site=="workshop" else tr("武器坊 / 守備器具"),x,284)
		var kind := "hammer" if site=="workshop" else "blade"
		for index in range(world.tools[kind]): _tool(Vector2(x-26+index*25,402),kind)
	_prop("forge",Vector2(world.sites.forge,430))
	_text(tr("義肢爐"),world.sites.forge,293)
	_prop("beacon",Vector2(world.sites.beacon,430),1.0,Color.WHITE if world.barrier>0 else Color(0.7,0.8,0.85))
	_text(tr("護民塔 ×%d") % world.barrier,world.sites.beacon,268)
	var wall_x: float = world.sites.wall
	if world.wall.level>0:
		var height: float = 76+world.wall.level*19
		draw_texture_rect(art.props.wall,Rect2(wall_x-27,430-height,54,height),false,Color.WHITE if world.wall.hp>0 else Color(0.4,0.35,0.38))
		draw_rect(Rect2(wall_x-30,418-height,60,4),Color("23313a"))
		draw_rect(Rect2(wall_x-30,418-height,60.0*world.wall.hp/(world.wall.level*40),4),Color("8cd5c6"))
	else: _prop("wall",Vector2(wall_x,430),1.0,Color(1,1,1,0.35))
	_text(tr("防線 %d/2") % world.wall.level,wall_x,282)
	if world.wall.pending: _text(tr("工匠施工中"),wall_x,306,Color("ead5aa"),13)
	var horn: float = world.sites.horn
	draw_line(Vector2(horn,350),Vector2(horn,430),Color("958771"),4)
	draw_circle(Vector2(horn,363),12,Color("c7a46a"))
	_text(tr("警鐘"),horn,332)
	for kind in ["hoe","bow"]:
		var x: float = world.tool_location(kind)
		_prop("workshop" if kind=="hoe" else "armory",Vector2(x,430),0.7)
		_text(tr("農具架") if kind=="hoe" else tr("獵具架"),x,324)
		for index in range(world.tools[kind]): _tool(Vector2(x-22+index*22,405),kind)
	var farm: float = world.sites.farm
	_prop("crops",Vector2(farm,430),1.0,Color.WHITE if map.farm_active else Color(0.55,0.65,0.55,0.5))
	_text(tr("農田 / 自動留種") if map.farm_active else tr("可開墾農地"),farm,345)
	if map.farm_active:
		draw_rect(Rect2(farm-44,351,88,3),Color("34443e"))
		draw_rect(Rect2(farm-44,351,88*map.farm_progress/map.farm_cycle,3),Color("d6dba2"))
	var drill: float = world.sites.drill
	draw_line(Vector2(drill,430),Vector2(drill,370),Color("ad9472"),5)
	draw_line(Vector2(drill-18,389),Vector2(drill+18,389),Color("a68f72"),5)
	draw_circle(Vector2(drill,373),9,Color("ccb78b"))
	_text(tr("訓練 %d/%d") % [map.drill_level,map.training_limit],drill,343)

func _resource(resource) -> void:
	var at := Vector2(resource.x,resource.y)
	if resource.y<430:
		var ladder_x: float = resource.x-22
		for side in [-5,5]: draw_line(Vector2(ladder_x+side,430),Vector2(ladder_x+side,resource.y),Color(Color("a99770"),_world_alpha),2)
		for y in range(int(resource.y),430,9): draw_line(Vector2(ladder_x-5,y),Vector2(ladder_x+5,y),Color(Color("b8a580"),_world_alpha),2)
	if resource.collected:
		if resource.kind=="tree": _prop("stump",at)
		if not resource.carried and not resource.delivered:
			_prop("cache",Vector2(resource.pickup_x,resource.pickup_y),0.4)
		return
	_prop("tree-plain" if resource.kind=="tree" and resource.crystals==0 else resource.kind,at)
	if resource.marked:_work_marker(resource,at)

func _outpost_visible(_region: Dictionary) -> bool:
	return true

func _work_marker(resource, at: Vector2) -> void:
	draw_line(at+Vector2(-27,0),at+Vector2(-27,-42),Color("d3b476"),2)
	draw_colored_polygon(PackedVector2Array([at+Vector2(-27,-42),at+Vector2(-9,-36),at+Vector2(-27,-29)]),Color("8fe2d0"))
	if resource.worker>=0:
		draw_rect(Rect2(at+Vector2(-20,4),Vector2(40,3)),Color("243940"))
		draw_rect(Rect2(at+Vector2(-20,4),Vector2(40*(1-resource.remaining_work/75.0),3)),Color("d3dca3"))
func _person(person: Dictionary, protected: bool) -> void:
	var at := Vector2(person.x,person.get("y",430.0))
	var direction: float = person.get("direction",1.0)
	var state: String = person.get("work_state","idle")
	var time: float = _sim.workforce.elapsed+float(_sim.world.people.find(person))*0.19
	at.y += -absf(sin(time*TAU*2))*0.8 if person.get("moving",false) else sin(time*2.6)*0.35
	var walk_step:=int(float(person.get("walk_distance",time*60.0))/7.5)
	var frame := walk_step%4 if person.get("moving",false) else 0
	var source: Rect2
	var texture: Texture2D
	if person.role=="engineer":
		var row := 0 if person.get("moving",false) or state=="climb" else 3
		if state=="work": row=1
		elif state=="haul": row=2
		frame = (walk_step%6 if person.get("moving",false) else int(time*8)%6) if row!=3 else int(time*3)%6
		source=Rect2(frame*64,row*64,64,64)
		texture=art.engineer_atlas
	else:
		var column: int = {"wanderer":0,"citizen":1,"farmer":2,"hunter":3,"guard":4}[person.role]
		source=Rect2(column*64,frame*64,64,64)
		texture=art.citizens_atlas
	draw_set_transform(at,0,Vector2(direction,1))
	_draw_person_texture(texture,source,Color(1,0.65,0.65) if person.hurt>0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	if protected and person.role!="wanderer": draw_arc(at+Vector2(0,-24),29,PI,TAU,16,Color("81ddda"),1)
	var label: String={"wanderer":tr("流浪者"),"citizen":tr("居民"),"engineer":tr("工匠"),"farmer":tr("農夫"),"hunter":tr("獵人"),"guard":tr("守備兵")}[person.role]
	if state=="haul": label=tr("搬運中")
	elif state=="work": label=tr("作業中")
	_text(label,at.x,at.y-55,Color("d6e2d6"),12)

func _draw_atmosphere(_left: float) -> void:
	pass

func _draw_unexplored(_region: Dictionary) -> void:
	pass

func _draw_person_texture(texture: Texture2D, source: Rect2, tint: Color) -> void:
	draw_texture_rect_region(texture,Rect2(-32,-62,64,64),source,tint)
