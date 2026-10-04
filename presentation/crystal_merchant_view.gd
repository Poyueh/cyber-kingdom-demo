extends RefCounted
## Uses the same authored eight-frame resident atlas and compact pixel scale.
const Merchant = preload("res://domain/crystal_merchant.gd")
const People = preload("res://presentation/compact_people.gd")
const ATLAS: Texture2D = preload("res://art/characters/resident-motion-v002/residents.png")
const Icons = preload("res://presentation/ui_icons.gd")

static func draw_on(view: Node2D, trader: Merchant, elapsed: float, hero_x: float, highlighted: bool) -> void:
	if not trader.visible() or not view._on_screen(trader.x,100):return
	var alpha: float=1.0
	if trader.phase==Merchant.Phase.APPROACHING:
		alpha=clampf((float(trader.rules.merchant_approach)-absf(trader.x-hero_x))/100.0,0.0,1.0)
	if trader.phase in [Merchant.Phase.OUTBOUND,Merchant.Phase.RETURNING]:
		alpha=clampf((float(trader.rules.merchant_trip)-absf(trader.x-trader.home_x))/150.0,0.0,1.0)
	if alpha<=0:return
	var frame: int=int(fposmod(trader.walk_distance/32.0,1.0)*8) if trader.moving else int(elapsed*3)%8
	var row: int=2 if trader.moving else 3
	var facing: int=trader.facing if trader.moving else (1 if hero_x>=trader.x else -1)
	var bob: float=roundf(sin(elapsed*2)*1.0) if not trader.moving else roundf(sin(frame*PI/2)*1.0)
	var tint: Color=Color(1.6,1.65,1.35,alpha) if highlighted else Color(1.0,0.88,0.67,alpha)
	view.draw_set_transform(Vector2(roundf(trader.x),430),0,Vector2(facing,1))
	# Brass-framed cargo backpack behind the moving body, on the same pixel grid.
	var pack: PackedVector2Array=PackedVector2Array([Vector2(-22,-33+bob),Vector2(-18,-38+bob),Vector2(-10,-36+bob),Vector2(-8,-18+bob),Vector2(-19,-15+bob),Vector2(-24,-20+bob)])
	view.draw_colored_polygon(pack,Color(0.14,0.2,0.22,alpha))
	view.draw_rect(Rect2(-21,-31+bob,11,13),Color(0.38,0.26,0.18,alpha))
	view.draw_rect(Rect2(-22,-33+bob,12,4),Color(0.59,0.43,0.26,alpha))
	view.draw_rect(Rect2(-18,-32+bob,2,14),Color(0.8,0.61,0.33,alpha))
	view.draw_rect(Rect2(-19,-26+bob,4,3),Color(0.2,0.3,0.31,alpha))
	view.draw_rect(Rect2(-21,-38+bob,3,6),Color(0.33,0.89,0.8,alpha))
	view.draw_rect(Rect2(-15,-39+bob,3,7),Color(0.56,1.0,0.89,alpha))
	People.draw(view,ATLAS,Rect2(frame*64,row*64,64,64),tint)
	view.draw_set_transform(Vector2.ZERO)
	var icon: String="crystal" if trader.carrying_reward() else "trade"
	var at: Vector2=Vector2(trader.x,368+sin(elapsed*2.6)*2)
	view.draw_texture_rect(Icons.get_icon(icon),Rect2(at-Vector2(12,12),Vector2(24,24)),false,Color(0.75,1.0,0.87,alpha))
