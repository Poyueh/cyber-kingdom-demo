extends Resource
@export var options: Array[Resource]
func find(id: int) -> Resource:
	for option: Resource in options:
		if option.pace_id==id:return option
	return null
func valid() -> bool:
	if options.size()!=3:return false
	var seen: Array[int]=[]
	for option: Resource in options:
		if option==null or option.pace_id not in [0,1,2] or seen.has(option.pace_id):return false
		if option.title_key.is_empty() or option.description_key.is_empty() or option.icon.is_empty():return false
		seen.append(option.pace_id)
	return true
