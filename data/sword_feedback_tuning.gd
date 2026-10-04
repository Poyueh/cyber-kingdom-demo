extends Resource
## Presentation only. These values never change damage, reach or save data.
@export_group("Blade light")
@export var edge_color: Color = Color("123e52")
@export var trail_color: Color = Color("2ae7ef")
@export var core_color: Color = Color("e8ffec")
@export var heavy_color: Color = Color("ffc77b")
@export_range(32,80,1) var trail_radius: float = 54.0
@export_range(3,20,1) var light_width: float = 9.0
@export_range(3,24,1) var heavy_width: float = 15.0
@export_group("Confirmed contact")
@export_range(0,0.12,0.005) var light_stop: float = 0.05
@export_range(0,0.12,0.005) var heavy_stop: float = 0.085
@export_range(0,5,0.25) var light_kick: float = 1.75
@export_range(0,5,0.25) var heavy_kick: float = 3.5
@export_range(0.08,0.4,0.01) var light_lifetime: float = 0.20
@export_range(0.08,0.4,0.01) var heavy_lifetime: float = 0.28
@export_range(1,12,1) var max_contacts: int = 8
