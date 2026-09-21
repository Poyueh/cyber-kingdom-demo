extends Node2D
var strength: float=0.065
var _quad: ColorRect
var _material: ShaderMaterial
func _ready() -> void:
 z_index=40
 _quad=ColorRect.new();_quad.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _material=ShaderMaterial.new();_material.shader=preload("res://presentation/sunbeams.gdshader")
 _quad.material=_material;add_child(_quad)
func present(sim: RefCounted) -> void:
 var inverse: Transform2D=get_viewport().get_canvas_transform().affine_inverse()
 var top: Vector2=inverse*Vector2.ZERO
 var end: Vector2=inverse*get_viewport_rect().size
 _quad.position=top;_quad.size=Vector2(end.x-top.x,maxf(0,450-top.y))
 var phase: float=1.0-sim.clock.remaining/(sim.clock.night_seconds if sim.clock.is_night else sim.clock.day_seconds)
 var light: float=0.0 if sim.clock.is_night else smoothstep(0,0.15,phase)*(1.0-smoothstep(0.7,1.0,phase))
 _material.set_shader_parameter("daylight",light)
 _material.set_shader_parameter("elapsed",sim.workforce.elapsed)
 _material.set_shader_parameter("camera_x",top.x)
 _material.set_shader_parameter("intensity",strength)
