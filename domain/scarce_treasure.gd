extends RefCounted
## Select from authored ruins without disturbing world generation's random stream.
static func apply(map: RefCounted, camp_x: float, rules: Dictionary, rng: RandomNumberGenerator) -> void:
	if not rules.has("treasure_limit"):return # Historical layouts remain unchanged.
	var candidates: Array[RefCounted] = []
	for node: RefCounted in map.nodes:
		if node.kind=="cache" and absf(node.x-camp_x)>=float(rules.treasure_camp_distance):candidates.append(node)
	for index: int in range(candidates.size()-1,0,-1):
		var other: int = rng.randi_range(0,index)
		var swap: RefCounted = candidates[index]
		candidates[index]=candidates[other];candidates[other]=swap
	var chosen: Array[RefCounted] = []
	# Prefer one reward on each side before considering a third distant ruin.
	for side: int in [-1,1,0]:
		for node: RefCounted in candidates:
			if chosen.size()>=int(rules.treasure_limit):break
			if node in chosen or (side!=0 and signf(node.x-camp_x)!=side):continue
			if chosen.any(func(other: RefCounted) -> bool: return absf(other.x-node.x)<float(rules.treasure_spacing)):continue
			chosen.append(node)
			if side!=0:break
	map.nodes=map.nodes.filter(func(node: RefCounted) -> bool: return node.kind!="cache" or node in chosen)
