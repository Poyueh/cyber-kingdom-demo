extends Resource
## Presentation colours; the campaign clock remains the only time authority.
@export var daylight: Color=Color("fff3d9")
@export var sunset_light: Color=Color("d8a0a1")
@export var night_light: Color=Color("778eba")
@export var dawn_light: Color=Color("ae9ab7")
@export var day_sky: Color=Color("548fba")
@export var day_horizon: Color=Color("d4caa1")
@export var sunset_sky: Color=Color("665078")
@export var sunset_horizon: Color=Color("ef8b60")
@export var night_sky: Color=Color("101a39")
@export var night_horizon: Color=Color("343959")
@export_range(8.0,28.0) var sun_radius: float=17.0

@export var dawn_sky: Color
@export var dawn_horizon: Color
@export_range(0.0,0.6) var sun_halo_strength: float
@export_range(0.0,0.4) var moon_halo_strength: float
@export_range(2.0,7.0) var halo_extent: float
