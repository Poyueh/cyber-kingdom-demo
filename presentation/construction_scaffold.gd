extends RefCounted
static var _bases: Dictionary[int,Rect2i]={}
## Scaffolding and an open passage communicate that defenses are offline.
static func draw_on(view: Node2D, at: Vector2, height: float, progress: float, alpha: float) -> void:
	if not view._on_screen(at.x, 100): return
	var timber: Color = Color("8c7552")
	timber.a = alpha
	var iron: Color = Color("434c4c")
	iron.a = alpha
	for side: int in [-1,1]:
		view.draw_rect(Rect2(at+Vector2(side*32-2,-height),Vector2(4,height)), timber)
		view.draw_rect(Rect2(at+Vector2(side*32-5,-4),Vector2(10,4)), iron)
	for y: float in [-height+8,-height*0.5]:
		view.draw_rect(Rect2(at+Vector2(-38,y),Vector2(76,4)), timber)
	view.draw_line(at+Vector2(-30,-height+12),at+Vector2(30,-height*0.5), timber, 2)
	view._icon("hammer",at+Vector2(0,-height-15),22,Color(1.0,0.82,0.5,alpha))
	view.draw_rect(Rect2(at+Vector2(-28,-height-3),Vector2(56,3)), iron)
	view.draw_rect(Rect2(at+Vector2(-28,-height-3),Vector2(56*clampf(progress,0,1),3)),Color(0.8,0.72,0.47,alpha))

## A breached defense has an open silhouette; repairs retain their scaffold.
static func ruins(view: Node2D, at: Vector2, texture: Texture2D) -> void:
	if not view._on_screen(at.x,100):return
	var key: int=texture.get_instance_id()
	if not _bases.has(key):_bases[key]=texture.get_image().get_used_rect()
	var used: Rect2i=_bases[key]
	var base: Rect2=Rect2(used.position.x,used.end.y-18,used.size.x,18)
	view.draw_texture_rect_region(texture,Rect2(at+Vector2(-used.size.x*0.5,-18),Vector2(used.size.x,18)),base,Color("706256"))
	for piece: int in range(7):
		var x: float=-46+piece*14
		var height: float=5+posmod(piece*7,9)
		view.draw_rect(Rect2(at+Vector2(x,-height),Vector2(12,height)),Color("394248"))
		view.draw_line(at+Vector2(x,-height),at+Vector2(x+10,-height),Color("71695a"),2)
	view.draw_line(at+Vector2(-28,-3),at+Vector2(20,-16),Color("836341"),5)
	view.draw_line(at+Vector2(-17,-12),at+Vector2(39,-2),Color("4f4234"),4)
