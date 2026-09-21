extends RefCounted
## HUD-only geometry. Safe pixels are projected through the viewport stretch transform.
static func screen_to_canvas(viewport: Rect2, to_screen: Transform2D, safe_pixels: Rect2) -> Rect2:
	if not safe_pixels.has_area() or is_zero_approx(to_screen.determinant()):return viewport
	var result: Rect2=(to_screen.affine_inverse()*safe_pixels).intersection(viewport)
	return result if result.has_area() else viewport

static func arrange(safe: Rect2, corner_menu: bool=false) -> Dictionary:
	var width:=safe.size.x
	var bottom:=safe.size.y-80
	var buttons: Dictionary={}
	for i in range(3):
		buttons[["move_left","move_right","drop"][i]]=Rect2(16+i*74,bottom,64,64)
	for i in range(4):
		buttons[["attack","jump","dash","interact"][i]]=Rect2(width-80-i*74,bottom,64,64)
	for i in range(3):
		buttons[["pause","fullscreen","save"][i]]=Rect2(16+i*74 if corner_menu else width-80-i*74,14,64,64)
	var wide:=width>=832
	var mission_y:=86.0 if wide else 130.0
	for i in range(4):
		buttons[["refuge","restart","new_map","audio"][i]]=Rect2(398,90+i*74,64,64) if corner_menu else Rect2(width-80-i*74,mission_y+48,64,64)
	var panels: Dictionary={"health":Rect2(16,14,212,38),"crystal":Rect2(236,14,78,38)}
	for i in range(6):
		panels[["wood","food","stone","herbs","scrap","damage"][i]]=Rect2(16+i*70,86,62 if i<5 else 72,38)
	panels.day=Rect2(width*0.5-88,14,176,34) if wide else Rect2(width-192,86,176,34)
	var column:=width-336 if wide else (width-320)*0.5
	panels.raid_left=Rect2(column,mission_y,64,34)
	panels.core=Rect2(column+72,mission_y,176,34)
	panels.raid_right=Rect2(column+256,mission_y,64,34)
	panels.overlay=Rect2(Vector2(width*0.5,safe.size.y*0.5)-Vector2(52,48),Vector2(104,96))
	for collection in [buttons,panels]:
		for key in collection:collection[key].position+=safe.position
	return {"buttons":buttons,"panels":panels}
