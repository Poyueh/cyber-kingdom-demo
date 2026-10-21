extends RefCounted
## Wanderers wait on open ground, never under a standing tree's canopy.
## Pure positions along the ground line; trees are harvest nodes of kind "tree".
## Half the widest tree sprite (the 164 px oak) plus its 3 px wind sway.
const TREE_CANOPY: float=85.0
## Half of a resident's body within the 64 px frame.
const BODY_HALF: float=14.0
## A wanderer left under a tree looks for open ground this far either way.
const REACH: float=240.0
## A clearing leaves at least one more body width to shuffle in, not a squeeze between
## two canopies.
const CLEARING: float=28.0
## A body exactly at a canopy's edge is beside the tree; saved positions keep that answer.
const EDGE_TOLERANCE: float=0.01

## Ground covered by standing trees, as sorted, merged [left, right] intervals.
static func tree_cover(nodes: Array) -> Array[Vector2]:
	var spans: Array[Vector2]=[]
	for node: RefCounted in nodes:
		if node.kind=="tree" and not node.collected:spans.append(Vector2(node.x-TREE_CANOPY,node.x+TREE_CANOPY))
	spans.sort_custom(func(a: Vector2,b: Vector2)->bool:return a.x<b.x)
	var merged: Array[Vector2]=[]
	for span: Vector2 in spans:
		if not merged.is_empty() and span.x<=merged.back().y:merged[merged.size()-1]=Vector2(merged.back().x,maxf(merged.back().y,span.y))
		else:merged.append(span)
	return merged

## Whether a resident standing at x stays clear of every canopy.
static func clear(x: float, cover: Array[Vector2]) -> bool:
	for span: Vector2 in cover:
		if x+BODY_HALF>span.x+EDGE_TOLERANCE and x-BODY_HALF<span.y-EDGE_TOLERANCE:return false
	return true

## The clearing spot within [low, high] nearest to x; NAN when trees fill the whole range.
static func spot(x: float, cover: Array[Vector2], low: float, high: float) -> float:
	var best: float=NAN
	for gap: Vector2 in _gaps(cover,low,high):
		if gap.y-gap.x<CLEARING:continue
		var at: float=clampf(x,gap.x,gap.y)
		if is_nan(best) or absf(at-x)<absf(best-x):best=at
	return best

## The clearing nearest to x within [low, high]. In a wood too dense for any clearing,
## the point there farthest from every trunk.
static func settle(x: float, nodes: Array, low: float, high: float) -> float:
	var at: float=spot(x,tree_cover(nodes),low,high)
	return _least_covered(x,nodes,low,high) if is_nan(at) else at

static func _least_covered(x: float, nodes: Array, low: float, high: float) -> float:
	var trunks: Array[float]=[]
	for node: RefCounted in nodes:
		if node.kind=="tree" and not node.collected:trunks.append(node.x)
	if trunks.is_empty():return x
	trunks.sort()
	var candidates: Array[float]=[low,high]
	for i: int in range(trunks.size()-1):candidates.append((trunks[i]+trunks[i+1])*0.5)
	var best: float=x
	var best_room: float=-INF
	for at: float in candidates:
		if at<low or at>high:continue
		var room: float=INF
		for trunk: float in trunks:room=minf(room,absf(trunk-at))
		if room>best_room+EDGE_TOLERANCE or (absf(room-best_room)<=EDGE_TOLERANCE and absf(at-x)<absf(best-x)):
			best=at;best_room=room
	return best

## Where a wanderer strolls from: their roaming home, moved out from under a tree
## (for example a resident knocked back to wanderer there) when open ground is in reach.
static func home_for(person: Dictionary, cover: Array[Vector2], low: float, high: float) -> float:
	var settled: bool=person.get("roam_role","")=="wanderer"
	var home: float=person.roam_home if settled else person.x
	if clear(home,cover):return home
	var open: float=spot(home,cover,maxf(low,home-REACH),minf(high,home+REACH))
	if is_nan(open):return home
	if settled:person.roam_home=open
	return open

## The open stretch around a clear spot, bounded by [low, high].
static func span(x: float, cover: Array[Vector2], low: float, high: float) -> Vector2:
	for gap: Vector2 in _gaps(cover,low,high):
		if x>=gap.x and x<=gap.y:return gap
	return Vector2(x,x)

## Positions where a resident's body fits between canopies, within [low, high].
static func _gaps(cover: Array[Vector2], low: float, high: float) -> Array[Vector2]:
	var gaps: Array[Vector2]=[]
	var start: float=low
	for span: Vector2 in cover:
		if span.y<=low:continue
		if span.x>=high:break
		var end: float=span.x-BODY_HALF
		if end>=start:gaps.append(Vector2(start,end))
		start=maxf(start,span.y+BODY_HALF)
	if high>=start:gaps.append(Vector2(start,high))
	return gaps
