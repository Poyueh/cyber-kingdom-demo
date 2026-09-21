extends RefCounted
## Optional presentation-only scenery. Time is supplied by the paused simulation.
static func forest(canvas: Node2D, texture: Texture2D, bounds: Rect2, scroll: float) -> void:
	if texture == null: return
	preload("res://presentation/scenery_tiles.gd").draw(canvas,texture,bounds,468-texture.get_height(),scroll)

static func river(canvas: Node2D, art: Resource, sim, bounds: Rect2) -> void:
	var line: float = 465.0
	if bounds.end.y <= line: return
	# Extend water beneath the authored bank on tall/zoomed-out viewports.
	if bounds.end.y > 541:
		canvas.draw_rect(Rect2(bounds.position.x,541,bounds.size.x,bounds.end.y-541),Color("172849"))
	var time: float = sim.workforce.elapsed
	var hall: float = sim.world.sites.hall
	var entries: Array = [["campfire",hall+(104 if sim.frontier.city_level>0 else 0),0.7 if sim.frontier.city_level>0 else 1.0]]
	if art.props.has("relay"): entries.append(["relay",hall-115,0.8])
	if sim.frontier.city_level > 0:
		entries.append(["hall-%d" % sim.frontier.city_level,hall,1.0])
		if art.props.has("relay"): entries.append(["relay",sim.world.sites.workshop-100,0.8])
		for site in ["workshop","armory","farm_tools","hunt_tools","forge","beacon"]:
			if sim.built.get(site,false):
				entries.append([{"farm_tools":"workshop","hunt_tools":"armory"}.get(site,site),sim.world.sites[site],0.7 if site in ["farm_tools","hunt_tools"] else 1.0])
	for entry in entries:
		var texture: Texture2D = art.props.get(entry[0])
		if texture == null: continue
		var scale: float = entry[2]
		var width: float = texture.get_width()*scale
		var x: float = entry[1]-width*0.5
		if x+width < bounds.position.x or x > bounds.end.x: continue
		var height: float = minf(texture.get_height()*scale*0.55,bounds.end.y-line)
		for row in range(0,ceili(height),3):
			var strip: float = minf(3,height-row)
			var source_height: float = strip/(scale*0.55)
			var source_y: float = texture.get_height()-(row+strip)/(scale*0.55)
			var drift := roundf(sin(time*1.7+row*0.23+float(entry[1])*0.01)*3)
			canvas.draw_texture_rect_region(texture,Rect2(x+drift,line+row,width,strip),Rect2(0,source_y,texture.get_width(),source_height),Color(0.65,0.8,1,0.34*(1-row/maxf(height,1))))
	# Restrained horizontal glints, anchored in world space.
	for index in range(floori(bounds.position.x/90),ceili(bounds.end.x/90)):
		var x := index*90.0+sin(time*0.65+index)*5
		var y := line+8+fposmod(index*19.0,70)
		canvas.draw_rect(Rect2(x,y,18+fposmod(index*13.0,30),1),Color(0.35,0.49,0.68,0.15))
