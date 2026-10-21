extends RefCounted
## Deterministic idle destinations; jobs and recruitment are selected by the session.
## wild_home: where a new wanderer settles (open ground); defaults to where they stand.
static func destination(person: Dictionary, index: int, center: float, radius: float, seconds: float, left: float, right: float, wild_home: float=NAN) -> float:
	if person.get("roam_role","")!=person.role:
		person.roam_role=person.role
		person.roam_home=(person.x if is_nan(wild_home) else wild_home) if person.role=="wanderer" else center
		person.roam_leg=0
		person.roam_wait=1.2+fmod(index*0.37,1.0)
		person.roam_target=clampf(person.x,person.roam_home-radius,person.roam_home+radius)
	var home: float=person.roam_home if person.role=="wanderer" else center
	var low:=maxf(left,home-radius)
	var high:=minf(right,home+radius)
	person.roam_target=clampf(person.roam_target,low,high)
	if absf(person.x-person.roam_target)>0.5: return person.roam_target
	person.roam_wait=maxf(0,person.roam_wait-seconds)
	if person.roam_wait>0: return person.x
	person.roam_leg+=1
	var sign: float=1.0 if (person.roam_leg+index)%2 else -1.0
	var distance:=radius*(0.55+fmod(index*0.17+person.roam_leg*0.13,0.4))
	person.roam_target=clampf(home+sign*distance,low,high)
	person.roam_wait=1.0+fmod(index*0.41+person.roam_leg*0.27,1.6)
	return person.roam_target
