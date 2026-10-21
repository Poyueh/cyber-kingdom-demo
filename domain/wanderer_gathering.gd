extends RefCounted
## Where a supply region's wanderers gather. New journeys (economy forest_clearing) gather
## 12% in from the region's outer edge, in the clearing the forest leaves there, with its
## trees toward camp. Worlds created before keep 12% from the west edge: saved worlds are
## rebuilt from their own rules and must keep their original trees and newcomers.
const SHARE: float=0.12
var clearing: bool=false

func _init(economy: Dictionary={}) -> void:
	clearing=int(economy.get("forest_clearing",0))==1

func x(region_x: float, width: float) -> float:
	if clearing and region_x+width*0.5>0.0:return region_x+width*(1.0-SHARE)
	return region_x+width*SHARE
