extends Resource
## Values are authored once in crystal_merchant.tres, including map scarcity.
@export_range(1,12,1) var delivery_crystals: int
@export_range(1,12,1) var trip_cost: int
@export_range(20,200,5) var walking_speed: float
@export_range(30,120,5) var gift_radius: float
@export_range(300,1200,25) var approach_distance: float
@export_range(300,1200,25) var trip_distance: float
@export_range(100,600,10) var camp_offset: float
@export_range(0,5,1) var treasure_limit: int
@export_range(1000,5000,100) var treasure_camp_distance: float
@export_range(1000,5000,100) var treasure_spacing: float

func rules() -> Dictionary:
	return {"merchant_enabled":1,"merchant_delivery":delivery_crystals,"merchant_cost":trip_cost,
		"merchant_speed":walking_speed,"merchant_radius":gift_radius,"merchant_approach":approach_distance,
		"merchant_trip":trip_distance,"merchant_offset":camp_offset,"treasure_limit":treasure_limit,
		"treasure_camp_distance":treasure_camp_distance,"treasure_spacing":treasure_spacing}
