extends "res://data/frontier_tuning.gd"
@export_group("Resident work territory")
@export_range(200,1600,50) var work_margin: float=preload("res://domain/resident_work_area.gd").DEFAULT_MARGIN
const Spirit=preload("res://application/spirit_guidance.gd")
@export_group("Spirit guidance")
@export_range(30,600,5) var spirit_opening_seconds: float=Spirit.OPENING_SECONDS
@export_range(6,60,1) var spirit_visit_seconds: float=Spirit.VISIT_SECONDS
@export_group("Immersive journey")
@export var immersive_loop: bool=true
@export var crystal_survival: bool=true
@export_range(1,10,1) var hit_crystal_loss: int=3
@export_range(1,30,1) var rest_regen: float=10.0
@export_range(20,100,5) var knight_health: int=70
@export_range(5,30,1) var knight_damage: int=18
@export_group("Special modules")
@export_range(1,100,1) var module_arc_damage: int=32
@export_range(1,60,1) var module_arc_cost: float=20.0
@export_range(60,400,10) var module_arc_range: float=150.0
@export_range(1,30,0.5) var module_arc_cooldown: float=6.0
@export_range(1,150,1) var module_lance_damage: int=55
@export_range(1,60,1) var module_lance_cost: float=25.0
@export_range(60,600,10) var module_lance_range: float=300.0
@export_range(1,30,0.5) var module_lance_cooldown: float=8.0
@export_group("Exploration")
@export_range(0,8,1) var outer_regions_per_side: int = 7
@export_range(300,1250,50) var arrival_walk_distance: float=1050.0
@export_group("Final dragon")
@export_range(2,20,1) var dragon_baseline_day: int=6
@export_range(100,6000,100) var dragon_health: int=1800
@export_range(10,100,1) var dragon_damage: int=36
@export_range(0,1000,20) var dragon_daily_health: int=240
@export_range(0,20,1) var dragon_daily_damage: int=4
@export_group("Presentation")
@export_range(1.0,1.4,0.05) var camera_zoom: float = 1.15
@export var larger_desktop_window: bool = true
@export_group("Fast running")
@export var travel_recovery: Resource=preload("res://data/travel_recovery.tres")
@export_range(60,190,5) var walking_speed: float=165.0
@export_range(1.1,3.0,0.05) var fast_run_multiplier:=1.95
@export_range(5,40,1) var fast_run_drain:=18.0
@export_group("Knight stamina")
@export_range(1,50,1) var attack_stamina: float=12.0
@export_range(1,50,1) var jump_stamina: float=18.0
@export_range(1,80,1) var dash_stamina: float=30.0
@export_group("Knight backpack")
@export_range(2,30,1) var backpack_capacity: int = 30
@export_range(0,30,1) var initial_crystals: int = 6
@export_group("Hold to invest")
@export_range(0.2,1.5,0.05) var investment_hold_delay: float = 0.5
@export_range(0.1,1,0.05) var investment_interval: float = 0.28
@export_range(0.1,3.0,0.1) var investment_refund_delay: float=1.0
@export_group("Crystal motion")
@export_range(48,220,4) var magnet_radius: float = 112.0
@export_range(100,600,10) var magnet_speed: float = 300.0
@export_range(0.5,4,0.1) var throw_grace: float = 2.0
@export_range(6,14,1) var crystal_radius: float = 9.0
@export_group("Resident stroll")
@export_range(8,50,1) var stroll_speed: float = 24.0
@export_group("Crystal harvest")
@export_range(1,12,1) var tree_crystals: int = 4
@export_range(1,12,1) var mineral_crystals: int = 6
@export_range(1,12,1) var chest_crystals: int = 6
@export_range(1,12,1) var plant_crystals: int = 3
@export_group("Frontier renewal")
var tree_timber: int = 4 # Legacy checkpoint configuration only.
@export_range(8,40,1) var population_limit: int = 24
@export_range(1,4,1) var camp_waiting_limit: int = 2
@export_group("Knight growth")
@export_range(1,3,1) var capacitor_limit: int = 3
@export_range(0,3,1) var growth_crystal_step: int = 1
var growth_scrap_step: int = 1
@export_range(1,6,1) var shield_charge_cost: int = 1
var shield_charge_scrap: int = 1
@export_group("Core and expedition")
@export_range(40,600,10) var core_max_hp: int = 180
@export_range(10,180,10) var core_recharge: int = 60
@export_range(2,30,1) var rift_seal_seconds: float = 8.0
@export_range(40,300,10) var warden_health: int = 90
@export_range(5,60,1) var warden_damage: int = 18
@export_group("Defense posts")
@export_range(40,120,5) var wall_clearance: float = 80.0
@export_range(-1200,-950,10) var left_defense_x: float = -1100.0
@export_group("Resident night safety")
@export_range(0,60,1) var return_margin: float = 15.0
@export_range(1,30,1) var hunter_damage: int = 12
@export_range(50,240,5) var hunter_range: float = 170.0
@export_range(0.4,3,0.1) var hunter_interval: float = 1.2
@export_group("Fortifications")
@export_range(1,30,0.5) var building_seconds:=3.0
@export_range(1,100,1) var tower_damage:=12
@export_range(200,800,20) var tower_range:=460.0
@export_group("Days and nights")
@export_range(30,600,10) var day_seconds: float = 180.0
@export_range(10,300,5) var night_seconds: float = 60.0
@export_range(1,50,1) var enemy_health_growth: int = 12
@export_range(1,20,1) var enemy_damage_growth: int = 3
@export_group("Crystal slots per interaction")
@export var crystal_prices: Dictionary = {"module_swap":preload("res://application/knight_modules.gd").DEFAULT_SWAP_COST,"spirit":1,"camp":2,"hall":5,"workshop":2,"armory":3,"farm_tools":2,"hunt_tools":3,"forge":2,"beacon":1,"wall":3,"wall_upgrade":4,"repair":2,"farm":3,"drill":2,"outpost":3,"mark":1,"recruit":1,"core_charge":2,"rift":4,"heal":2}
func campaign_rules() -> Dictionary:
	return {"work_margin":work_margin,"module_arc_damage":module_arc_damage,"module_arc_cost":module_arc_cost,"module_arc_range":module_arc_range,"module_arc_cooldown":module_arc_cooldown,"module_lance_damage":module_lance_damage,"module_lance_cost":module_lance_cost,"module_lance_range":module_lance_range,"module_lance_cooldown":module_lance_cooldown,"spirit_opening_seconds":spirit_opening_seconds,"spirit_visit_seconds":spirit_visit_seconds,"crystal_survival":int(crystal_survival),"hit_crystal_loss":hit_crystal_loss,"immersive_loop":int(immersive_loop),"rest_regen":rest_regen,"knight_health":knight_health,"knight_damage":knight_damage,"building_seconds":building_seconds,"tower_damage":tower_damage,"tower_range":tower_range,"breath_stop_seconds":travel_recovery.breath_stop_seconds,"tired_speed_multiplier":travel_recovery.tired_speed_multiplier,"run_recovery_ratio":travel_recovery.run_recovery_ratio,"sprint_recovery_ratio":travel_recovery.sprint_recovery_ratio,"sprint_rest_seconds":travel_recovery.sprint_rest_seconds,"fast_run_multiplier":fast_run_multiplier,"fast_run_drain":fast_run_drain,"dragon_baseline_day":dragon_baseline_day,"dragon_health":dragon_health,"dragon_damage":dragon_damage,"dragon_daily_health":dragon_daily_health,"dragon_daily_damage":dragon_daily_damage,"tree_crystals":tree_crystals,"mineral_crystals":mineral_crystals,"chest_crystals":chest_crystals,"plant_crystals":plant_crystals,"attack_stamina":attack_stamina,"jump_stamina":jump_stamina,"dash_stamina":dash_stamina,"wall_clearance":wall_clearance,"tree_timber":tree_timber,"population_limit":population_limit,"camp_waiting_limit":camp_waiting_limit,"capacitor_limit":capacitor_limit,"growth_crystal_step":growth_crystal_step,"growth_scrap_step":growth_scrap_step,"shield_charge_cost":shield_charge_cost,"shield_charge_scrap":shield_charge_scrap,"warden_health":warden_health,"warden_damage":warden_damage,"rift_seal_seconds":rift_seal_seconds,"core_max_hp":core_max_hp,"core_recharge":core_recharge,"left_defense_x":left_defense_x,"return_margin":return_margin,"hunter_damage":hunter_damage,"hunter_range":hunter_range,"hunter_interval":hunter_interval,"stroll_speed":stroll_speed,"magnet_radius":magnet_radius,"magnet_speed":magnet_speed,"throw_grace":throw_grace,"capacity":backpack_capacity,"starting_crystals":initial_crystals,"day_seconds":day_seconds,"night_seconds":night_seconds,"enemy_health_growth":enemy_health_growth,"enemy_damage_growth":enemy_damage_growth,"prices":crystal_prices}

func economy_rules() -> Dictionary:
	var rules:=super.economy_rules()
	rules["outer_regions_per_side"]=outer_regions_per_side
	return rules
