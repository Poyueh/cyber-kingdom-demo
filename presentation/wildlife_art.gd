extends RefCounted
## Complete native-resolution poses share a stable ground pivot and fixed scale.
const CAST: Array[WildlifeAppearance]=[
 null, preload("res://data/wildlife/hare.tres"), preload("res://data/wildlife/boar.tres"),
 preload("res://data/wildlife/fox.tres"), preload("res://data/wildlife/badger.tres"),
 preload("res://data/wildlife/goat.tres"), preload("res://data/wildlife/pheasant.tres"),
 preload("res://data/wildlife/tortoise.tres")]

static func paint(canvas: Node2D, species: int, at: Vector2, direction: float, distance: float, _moving: bool, tint: Color) -> void:
 var profile: WildlifeAppearance=CAST[species]
 # Distance freezes on stopping/pausing, so the whole pose freezes with it.
 var frame: int=int(floor(distance/profile.stride*profile.frame_count))%profile.frame_count
 var source: Rect2=Rect2(Vector2((frame%profile.columns)*profile.frame_size.x,(frame/profile.columns)*profile.frame_size.y),Vector2(profile.frame_size))
 canvas.draw_line(at+Vector2(-profile.shadow,1),at+Vector2(profile.shadow,1),Color(0.03,0.07,0.06,tint.a*0.32),2)
 canvas.draw_set_transform(at.round(),0,Vector2(direction,1))
 canvas.draw_texture_rect_region(profile.texture,Rect2(-profile.ground_pivot,Vector2(profile.frame_size)),source,tint)
 canvas.draw_set_transform(Vector2.ZERO)
