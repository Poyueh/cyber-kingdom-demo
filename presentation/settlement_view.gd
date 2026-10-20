extends Node2D
## World-space buildings, stock, people and feedback; simulation stays in application/domain.
const PeopleArt = preload("res://presentation/refuge_residents.gd")
const EnemyLook = preload("res://data/enemy_cast.tres")
## Art is anchored off centre, so a margin keeps it from popping at the edge.
const CULL_MARGIN := 160.0
var _sim
var _context: Dictionary = {}
var _font: Font
var _span := Vector2(-100000.0,100000.0)

## World-space horizontal range on screen; refreshed once per redraw.
func _refresh_span() -> void:
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	_span=Vector2((inverse*Vector2.ZERO).x,(inverse*get_viewport_rect().size).x)

func _on_screen(x: float, margin: float = CULL_MARGIN) -> bool:
	return x>=_span.x-margin and x<=_span.y+margin

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_font=preload("res://presentation/localized_font.gd").current()

func present(sim, player_x: float) -> void:
	_sim = sim
	_context = sim.context(player_x)
	queue_redraw()

func _text(text: String, x: float, y: float, color := Color("dbdac5"), size: int = 15) -> void:
	var width := _font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(_font,Vector2(x-width*0.5,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
	if _sim == null or _font == null:
		return
	_refresh_span()
	_draw_structures()
	_draw_activity()

func _draw_structures() -> void:
	var world = _sim.world
	for site in ["workshop","armory"]:
		var x: float = world.sites[site]
		draw_rect(Rect2(x-64,348,128,82),Color("263543"))
		draw_rect(Rect2(x-58,354,116,70),Color("344955"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-74,348),Vector2(x,317),Vector2(x+74,348)]),Color("5e5560"))
		draw_rect(Rect2(x-49,376,98,35),Color("111e2b"))
		draw_rect(Rect2(x-56,410,112,5),Color("9a8868"))
		var kind := "hammer" if site == "workshop" else "blade"
		for index in range(world.tools[kind]):
			_tool(Vector2(x-32+index*30,389),kind)
		_text(tr("工坊 / 工程錘") if site == "workshop" else tr("武器坊 / 守備器具"),x,303)
	var forge: float = world.sites.forge
	draw_rect(Rect2(forge-34,369,68,61),Color("344957"))
	draw_rect(Rect2(forge-24,379,48,29),Color("132332"))
	draw_colored_polygon(PackedVector2Array([Vector2(forge,346),Vector2(forge+12,363),Vector2(forge,385),Vector2(forge-12,363)]),Color("82e8df"))
	_text(tr("義肢爐"),forge,331)
	var beacon: float = world.sites.beacon
	draw_rect(Rect2(beacon-13,350,26,80),Color("425460"))
	draw_rect(Rect2(beacon-23,345,46,14),Color("65afac"))
	draw_circle(Vector2(beacon,333),12,Color("8ae9de") if world.barrier>0 else Color("38565e"))
	_text(tr("護民塔 ×%d") % world.barrier,beacon,310)
	var wall_x: float = world.sites.wall
	if world.wall.level == 0:
		for height in range(355,430,14):
			draw_rect(Rect2(wall_x-17,height,34,6),Color(0.5,0.7,0.75,0.5))
	else:
		var height: float = 76+world.wall.level*19
		draw_rect(Rect2(wall_x-22,430-height,44,height),Color("596975") if world.wall.hp>0 else Color("4a3640"))
		for row in range(int(height/18)):
			draw_line(Vector2(wall_x-21,430-row*18),Vector2(wall_x+21,430-row*18),Color("28333e"),2)
		draw_rect(Rect2(wall_x-30,324-height+100,60,5),Color("24323b"))
		draw_rect(Rect2(wall_x-30,424-height,60.0*world.wall.hp/(world.wall.level*40),5),Color("8ce0cc"))
	_text(tr("防線 Lv.%d") % world.wall.level,wall_x,280)
	if world.wall.pending:
		_text(tr("施工 %d%%") % mini(100,int(world.wall.progress/3*100)),wall_x,307,Color("f3bd7e"))
	var horn: float = world.sites.horn
	draw_line(Vector2(horn,350),Vector2(horn,430),Color("918475"),5)
	draw_rect(Rect2(horn-16,356,32,26),Color("c9a260"))
	_text(tr("警鐘"),horn,330)

func _draw_activity() -> void:
	var world = _sim.world
	for supply in world.supplies:
		if not supply.taken and _on_screen(supply.x):
			var y := 423.0 - maxf(0,1.0-supply.age/0.4)*24
			draw_rect(Rect2(supply.x-5,y-5,10,8),Color("e9bc67"))
	for drop in _sim.loot:
		if not drop.taken and _on_screen(drop.x):
			draw_rect(Rect2(drop.x-5,417,10,10),Color("c7b28d"))
	for person in world.people:
		if _on_screen(person.x):_person(person,world.barrier>0)
	for raider in _sim.raiders:
		if _on_screen(raider.x):_raider(raider)
	for effect in _sim.effects:
		match effect.kind:
			"bolt": draw_line(Vector2(effect.x,effect.get("y",396)),Vector2(effect.to,effect.get("target_y",396)),Color("91ece3"),2)
			"pay": draw_circle(Vector2(effect.x,380-(0.45-effect.life)*50),4,Color("f0ce82"))
			"hit": _hit_effect(effect)
	_draw_interaction()

func _hit_effect(effect: Dictionary) -> void:
	if not _on_screen(effect.x,80):return
	var heavy: bool=effect.get("heavy",false)
	var duration: float=0.28 if heavy else (0.20 if effect.has("heavy") else 0.25)
	preload("res://presentation/enemy_impact_view.gd").burst(self,Vector2(effect.x,398),clampf(1-effect.life/duration,0,1),effect.get("facing",1.0),heavy,Color("91e3d9"))

func _raider(raider: Dictionary) -> void:
	var look: EnemyAppearance=EnemyLook.grunt
	var frame: int=look.windup[0] if raider.windup>0 else look.sample(look.walk,fposmod(raider.x/look.stride,1.0))
	preload("res://presentation/raider_motion_view.gd").draw_pose(self,look,frame,Vector2(raider.x,430),raider.get("direction",-1.0),Color(2.3,2.1,1.8) if raider.fighter.invulnerability_remaining>0 else Color.WHITE)
	draw_rect(Rect2(raider.x-22,360,44,4),Color("482a3a"))
	draw_rect(Rect2(raider.x-22,360,44.0*raider.fighter.hp/raider.fighter.stats.max_hp,4),Color("df8491"))
	if raider.windup>0: _text("!",raider.x,348,Color("ffd087"),22)

func _draw_interaction() -> void:
	if not _context.id.is_empty():
		var x: float = _context.x
		draw_rect(Rect2(x-171,198,342,69),Color(0.04,0.10,0.15,0.97))
		_text(_context.text,x,222,Color("e4e3cd"),15)
		var hint := tr("E / 投入 %d %s") % [_context.cost,tr(_context.currency)] if _context.cost>0 else tr("E / 互動")
		if not _context.enabled: hint = _context.reason
		_text(hint,x,245,Color("81d4ce") if _context.enabled else Color("c7a48b"),14)
		for index in range(_context.cost):
			draw_circle(Vector2(x+(index-(_context.cost-1)*0.5)*12,258),3,Color("b9e9d9") if _context.currency=="龍晶" else Color("d6b87e"))

func _tool(at: Vector2, kind: String) -> void:
	var key: String="spear" if kind=="blade" else kind
	var texture: Texture2D=preload("res://presentation/ui_icons.gd").get_icon(key)
	draw_texture_rect(texture,Rect2(at.round()-Vector2(16,20),Vector2(32,40)),false)

func _person(person: Dictionary, protected: bool) -> void:
	var coat: Color = {"wanderer":Color("706477"),"citizen":Color("b78b65"),"engineer":Color("d3b066"),"guard":Color("78afba"),"farmer":Color("96b36c"),"hunter":Color("bd9872")}[person.role]
	var colors := {"h":Color("46323d"),"s":Color("d5ac91"),"c":coat,"b":Color("3c4e60")}
	for row in range(PeopleArt.PERSON.size()):
		for column in range(PeopleArt.PERSON[row].length()):
			var key: String = PeopleArt.PERSON[row][column]
			if colors.has(key): draw_rect(Rect2(roundf(person.x)-12+column*3,394+row*3,3,3),colors[key])
	if person.role == "engineer": _tool(Vector2(person.x+17,411),"hammer")
	if person.role == "guard": _tool(Vector2(person.x+17,411),"blade")
	if person.role == "farmer": _tool(Vector2(person.x+17,411),"hoe")
	if person.role == "hunter": _tool(Vector2(person.x+17,411),"bow")
	if protected and person.role != "wanderer": draw_arc(Vector2(person.x,408),27,PI,TAU,16,Color("77ded4"),1)
	var label: String = {"wanderer":tr("流浪者"),"citizen":tr("居民"),"engineer":tr("工程師"),"guard":tr("守備兵"),"farmer":tr("農夫"),"hunter":tr("獵人")}[person.role]
	_text(label,person.x,381,Color("e5a087") if person.hurt>0 else Color("bdd1cf"),12)
