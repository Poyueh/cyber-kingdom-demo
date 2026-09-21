extends Node2D
## Recolour the existing skyline and light the world canvas, leaving HUD untouched.
const Style=preload("res://data/daylight_style.gd")
var style: Style
var _sky: Sprite2D
var _light: CanvasModulate
var _material: ShaderMaterial

func _ready() -> void:
 _sky=Sprite2D.new()
 _sky.centered=false
 _sky.z_index=-1
 _material=ShaderMaterial.new()
 _material.shader=preload("res://presentation/daylight_sky.gdshader")
 _sky.material=_material
 add_child(_sky)
 _light=CanvasModulate.new()
 add_child(_light)

func present(clock: RefCounted, texture: Texture2D, bounds: Rect2) -> void:
 if _sky==null:return
 var phase: float=clampf(1.0-clock.remaining/(clock.night_seconds if clock.is_night else clock.day_seconds),0,1)
 var day: float=0.0 if clock.is_night else smoothstep(0,0.17,phase)*(1.0-smoothstep(0.65,0.93,phase))
 var dusk: float=(1.0-smoothstep(0,0.23,phase)) if clock.is_night else smoothstep(0.67,0.87,phase)
 var dawn: float=smoothstep(0.84,1,phase) if clock.is_night else 1.0-smoothstep(0,0.17,phase)
 var twilight_light: Color=style.night_light.lerp(style.sunset_light,dusk).lerp(style.dawn_light,dawn)
 _light.color=twilight_light.lerp(style.daylight,day)
 var top: Color=style.night_sky.lerp(style.sunset_sky,maxf(dusk,dawn)*0.8).lerp(style.day_sky,day)
 var horizon: Color=style.night_horizon.lerp(style.sunset_horizon,maxf(dusk,dawn)).lerp(style.day_horizon,day)
 _sky.texture=texture
 _sky.position=bounds.position
 _sky.scale=bounds.size/texture.get_size()
 _material.set_shader_parameter("sky_top",top)
 _material.set_shader_parameter("sky_horizon",horizon)
 _material.set_shader_parameter("daylight",day)
 _material.set_shader_parameter("warmth",maxf(dusk,dawn))
 _material.set_shader_parameter("phase",phase)
 _material.set_shader_parameter("night",clock.is_night)
 _material.set_shader_parameter("sun_radius",style.sun_radius)
 _material.set_shader_parameter("world_light",_light.color)
