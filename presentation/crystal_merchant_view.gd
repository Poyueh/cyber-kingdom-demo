extends RefCounted
## Complete authored poses, shared native pixel scale and a camp-derived tier.
const Merchant = preload("res://domain/crystal_merchant.gd")
const ATLAS: Texture2D = preload("res://art/characters/merchant-v001/merchant.png")
const Style = preload("res://data/cosmic_interface.tres")
const Icons = preload("res://presentation/ui_icons.gd")
const CELL: Vector2=Vector2(96,80)
const FOOT: Vector2=Vector2(48,74)

static func draw_on(view: Node2D, trader: Merchant, elapsed: float, hero_x: float, highlighted: bool, camp_level: int) -> void:
 if not trader.visible() or not view._on_screen(trader.x,100):return
 var alpha: float=opacity(trader,hero_x)
 if alpha<=0:return
 var frame: int=2+int(fposmod(trader.walk_distance/Style.merchant_stride,1.0)*6) if trader.moving else int(elapsed*Style.merchant_idle_fps)%2
 var tier: int=clampi(camp_level,1,3)-1
 var facing: int=trader.facing if trader.moving else (1 if hero_x>=trader.x else -1)
 var tint: Color=Color(1.08,1.08,1.0,alpha) if highlighted else Color(1,1,1,alpha)
 view.draw_set_transform(Vector2(roundf(trader.x),430),0,Vector2(facing,1))
 view.draw_texture_rect_region(ATLAS,Rect2(-FOOT,CELL),Rect2(Vector2(frame*96,tier*80),CELL),tint)
 view.draw_set_transform(Vector2.ZERO)
 var icon: String="crystal" if trader.carrying_reward() else "trade"
 var at: Vector2=Vector2(roundf(trader.x),roundf(430-Style.merchant_icon_height+sin(elapsed*2.6)*2))
 view.draw_texture_rect(Icons.get_icon(icon),Rect2(at-Vector2(10,10),Vector2(20,20)),false,Color(0.75,1.0,0.87,alpha))

static func opacity(trader: Merchant, hero_x: float) -> float:
 var alpha: float=1.0
 if trader.phase==Merchant.Phase.APPROACHING:
  alpha=clampf((float(trader.rules.merchant_approach)-absf(trader.x-hero_x))/100.0,0.0,1.0)
 if trader.phase==Merchant.Phase.OUTBOUND:
  alpha=clampf(absf(trader.trip_end_x-trader.x)/150.0,0.0,1.0)
 elif trader.phase==Merchant.Phase.RETURNING:
  alpha=clampf(absf(trader.trip_end_x-trader.x)/150.0,0.0,1.0)
 return alpha
