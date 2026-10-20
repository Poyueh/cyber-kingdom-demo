extends RefCounted
## Stable resident indices; forming a squad never creates another person.
var members: Array[int]=[]
var side: int=1
func _init(roster: Array[int]=[], from_side: int=1) -> void:
 members.assign(roster);side=from_side
func capture() -> Dictionary:
 return {"members":members.duplicate(),"side":side}
