extends Node2D
## Reusable light texture; illumination follows the knight without creating particles.
var style: Resource
var _light: PointLight2D
var _facing: int=1
var _amount: float=0.0
func _ready() -> void:
 z_index=6
 var gradient: Gradient=Gradient.new()
 gradient.colors=PackedColorArray([Color.WHITE,Color(1,1,1,0)])
 var texture: GradientTexture2D=GradientTexture2D.new()
 texture.width=128;texture.height=128;texture.gradient=gradient
 texture.fill=GradientTexture2D.FILL_RADIAL
 texture.fill_from=Vector2(0.5,0.5);texture.fill_to=Vector2(0.5,0)
 _light=PointLight2D.new();_light.texture=texture;_light.texture_scale=2.8
 _light.color=Color("6cfde2");_light.shadow_enabled=false
 add_child(_light)
 var ink: CanvasItemMaterial=CanvasItemMaterial.new();ink.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
 material=ink
func present(sim: RefCounted, knight: Node2D) -> void:
 var phase: float=1.0-sim.clock.remaining/(sim.clock.night_seconds if sim.clock.is_night else sim.clock.day_seconds)
 _amount=(1.0-smoothstep(0.84,1.0,phase)) if sim.clock.is_night else maxf(1.0-smoothstep(0.0,0.17,phase),smoothstep(0.67,0.93,phase))
 _facing=sim.hero.facing
 position=knight.visual.to_global(knight.visual.armor_socket()+Vector2(_facing*7,-4))
 visible=sim.hero.is_alive() and _amount>0.01
 _light.energy=style.lantern_energy*_amount
