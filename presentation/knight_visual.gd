extends "res://presentation/fighter_visual.gd"
## New locomotion drawings are isolated from the editable combat animation resource.
const MotionFrames=preload("res://data/knight_motion_frames.tres")
@export var running_atlas: Texture2D=preload("res://art/characters/combo-v005/run.png")
@export var texture_overrides: Dictionary = {}
@export var moving_attack_atlas: Texture2D
@export var combo_motion: Resource
const EquipmentShader=preload("res://presentation/knight_equipment.gdshader")
var equipment_material: ShaderMaterial
const MountedSheet=preload("res://art/characters/mounted-v001/mounted.png")
const UnarmedSheet=preload("res://art/characters/unarmed-v001/run.png")
var _unarmed: Sprite2D
var _unarmed_frame: AtlasTexture=AtlasTexture.new()
var unarmed: bool=false
var breathing: bool=false
var mounted:=false
var _mount: Sprite2D
var _mount_frame:=AtlasTexture.new()
var weapon_tier:=0
var armor_tier:=0
var _gait_time:=0.0
var _moving_attack: Sprite2D
var _moving_region:=AtlasTexture.new()
var _combo_attack: Sprite2D
var _combo_region:=AtlasTexture.new()
var _motion_time:=0.0
var _was_grounded:=true
var _landing:=0.0
func _init() -> void:
	_unarmed=Sprite2D.new()
	_unarmed.visible=false
	add_child(_unarmed)
	_mount=Sprite2D.new()
	_mount.name="MountedKnight"
	_mount.visible=false
	_mount.offset=Vector2(0,-26)
	add_child(_mount)
	_moving_attack=Sprite2D.new()
	_moving_attack.name="MovingAttack"
	_moving_attack.visible=false
	add_child(_moving_attack)
	_combo_attack=Sprite2D.new()
	_combo_attack.name="ComboAttack"
	_combo_attack.visible=false
	_combo_attack.offset=Vector2(0,-16)
	add_child(_combo_attack)
	sprite_frames=preload("res://data/knight_animation_frames.tres")
	_bind_motion()
	animation=&"idle"
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _ready() -> void:
	_bind_motion() # PackedScene may assign its own frames after _init.
	_apply_art_overrides()
func _bind_motion() -> void:
	sprite_frames=sprite_frames.duplicate()
	for clip in [&"run",&"jump"]:
		if sprite_frames.has_animation(clip): sprite_frames.remove_animation(clip)
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_speed(clip,MotionFrames.get_animation_speed(clip))
		for index in range(MotionFrames.get_frame_count(clip)):
			var drawing=MotionFrames.get_frame_texture(clip,index)
			if clip==&"run" and drawing is AtlasTexture and running_atlas!=null:
				drawing=drawing.duplicate();drawing.atlas=running_atlas
			sprite_frames.add_frame(clip,drawing,MotionFrames.get_frame_duration(clip,index))
func _apply_art_overrides() -> void:
	# Swap atlas pixels only; preserve user-edited frame duration, region and speed.
	for clip in sprite_frames.get_animation_names():
		for index in range(sprite_frames.get_frame_count(clip)):
			var source:=sprite_frames.get_frame_texture(clip,index)
			if source is AtlasTexture and source.atlas!=null and texture_overrides.has(source.atlas.resource_path):
				var replacement: AtlasTexture=source.duplicate()
				replacement.atlas=texture_overrides[source.atlas.resource_path]
				sprite_frames.set_frame(clip,index,replacement,sprite_frames.get_frame_duration(clip,index))

func reset_pose() -> void:
	super.reset_pose()
	_gait_time=0
	self_modulate=Color.WHITE
	_moving_attack.visible=false
	_combo_attack.visible=false
	_motion_time=0
	_landing=0
	_was_grounded=true
	rotation=0
	scale=Vector2.ONE
func present(pose: Dictionary, seconds: float) -> void:
	var striding: bool=pose.get("moving",false) and pose.get("grounded",true) and not pose.get("dashing",false)
	if striding and seconds>0 and is_finite(seconds):
		_gait_time+=seconds*float(pose.get("locomotion_rate",1.0))
	elif not striding and not pose.get("dashing",false):
		_gait_time=0
	super.present(pose,seconds)
	if equipment_material!=null:equipment_material.set_shader_parameter("facing",-1.0 if flip_h else 1.0)
	self_modulate=Color.WHITE
	_moving_attack.visible=false
	_combo_attack.visible=false
	_moving_attack.offset=Vector2.ZERO
	if mounted and pose.alive:
		_present_mount(pose,seconds)
		return
	_mount.visible=false
	_unarmed.visible=false
	if unarmed and pose.alive:
		_motion_time+=maxf(0,seconds)
		rotation=pose.facing*0.08 if breathing else 0
		scale=Vector2(1.02,0.94+sin(_motion_time*7)*0.018) if breathing else Vector2.ONE
		var drawing: int=int(fposmod(_gait_time*9,8)) if striding else 0
		_unarmed_frame.atlas=UnarmedSheet
		_unarmed_frame.region=Rect2((drawing%4)*128,(drawing/4)*96,128,96)
		_unarmed.texture=_unarmed_frame;_unarmed.flip_h=pose.facing<0
		_unarmed.visible=true;self_modulate=Color(1,1,1,0)
		return
	if hurt_active or not pose.alive: return
	var gait:=int(fposmod(_gait_time*sprite_frames.get_animation_speed(&"run"),sprite_frames.get_frame_count(&"run")))
	if animation==&"run": frame=gait
	if combo_motion==null and animation==&"attack" and int(pose.get("combo_step",0))==2:
		# Reverse time, not just the index: respect authored frame weights.
		frame=_action_frame(&"attack",1.0-clampf(float(pose.attack_progress),0.0,1.0))
	if seconds>0 and is_finite(seconds):
		_motion_time+=seconds
		_landing=maxf(0,_landing-seconds)
	var grounded: bool=pose.get("grounded",true)
	if grounded and not _was_grounded: _landing=0.12
	_was_grounded=grounded
	rotation=0
	scale=Vector2.ONE
	if not grounded and not pose.get("dashing",false) and float(pose.get("attack_progress",1.0))>=1:
		animation=&"jump"
		var vy: float=pose.get("vertical_speed",0.0)
		frame=0 if vy < -450 else (1 if vy < -80 else (2 if vy<80 else 3))
		offset=Vector2.ZERO
	elif animation==&"idle":
		offset=Vector2(0,sin(_motion_time*2.8)*0.7)
	elif animation==&"run":
		offset=Vector2(0,-absf(sin(_motion_time*TAU*3))*0.7)
	elif animation==&"attack":
		offset=Vector2.ZERO
	if _landing>0 and grounded:
		var amount:=sin(_landing/0.12*PI)*0.055
		scale=Vector2(1+amount,1-amount)
		offset.y+=amount*24

	if breathing:
		rotation=pose.facing*0.08+sin(_motion_time*5)*0.02
		scale=Vector2(1.02,0.94+sin(_motion_time*7)*0.018)
		offset.y=2
	if animation==&"attack" and combo_motion!=null and combo_motion.planted_atlas!=null:
		var step:=clampi(int(pose.get("combo_step",1)),1,3)
		var drawing: int=combo_motion.frame_at(step,float(pose.attack_progress))
		if striding and combo_motion.moving_atlas!=null:
			_moving_region.atlas=combo_motion.moving_atlas
			_moving_region.region=Rect2(drawing*160,((step-1)*8+gait)*128,160,128)
			_moving_attack.texture=_moving_region
			_moving_attack.flip_h=flip_h
			_moving_attack.offset=Vector2(0,-16)
			_moving_attack.visible=true
		else:
			_combo_region.atlas=combo_motion.planted_atlas
			_combo_region.region=Rect2(drawing*160,(step-1)*128,160,128)
			_combo_attack.texture=_combo_region
			_combo_attack.flip_h=flip_h
			_combo_attack.visible=true
		self_modulate=Color(1,1,1,0)
		offset=Vector2.ZERO
	elif striding and animation==&"attack" and moving_attack_atlas!=null:
		# Legacy fallback for scenes without the independently authored combo.
		_moving_region.atlas=moving_attack_atlas
		_moving_region.region=Rect2(frame*128,gait*96,128,96)
		_moving_attack.texture=_moving_region
		_moving_attack.flip_h=flip_h
		_moving_attack.visible=true
		self_modulate=Color(1,1,1,0)
		offset=Vector2.ZERO

func set_equipment(weapon: int, armor: int) -> void:
	weapon_tier=clampi(weapon,0,3)
	armor_tier=clampi(armor,0,3)
	if equipment_material==null:
		equipment_material=ShaderMaterial.new()
		equipment_material.shader=EquipmentShader
		material=equipment_material
		_combo_attack.material=equipment_material
		_moving_attack.material=equipment_material
	equipment_material.set_shader_parameter("weapon_tier",float(weapon_tier))
	equipment_material.set_shader_parameter("armor_tier",float(armor_tier))

func set_mounted(value: bool) -> void:
	mounted=value
	_mount.visible=value
	if not value:self_modulate=Color.WHITE

func _present_mount(pose: Dictionary, seconds: float) -> void:
	if seconds>0:_motion_time+=seconds
	_mount.visible=pose.alive
	self_modulate=Color(1,1,1,0)
	_moving_attack.visible=false;_combo_attack.visible=false
	_mount.flip_h=pose.facing<0
	var progress: float=pose.get("attack_progress",1.0)
	var index:=0
	if progress<1:
		var step: int=pose.get("combo_step",1)
		index=3 if progress<0.3 else 4 if progress<0.58 else 5
		if step==2:index=5 if progress<0.3 else 4 if progress<0.58 else 3
	elif not pose.get("grounded",true):index=2
	elif pose.get("moving",false) or pose.get("dashing",false):index=1+int(_motion_time*7)%2
	if hurt_active:index=0
	_mount_frame.atlas=MountedSheet
	_mount_frame.region=Rect2(index*160,0,160,128)
	_mount.texture=_mount_frame
	_mount.position=Vector2(0,-absf(sin(_motion_time*7))*1.5 if index in [1,2] else sin(_motion_time*2)*0.5)

	# Brace the horse through the cut, then ease back to a balanced stance.
	if progress<1 and not hurt_active:
		var thrust:=sin(clampf((progress-0.2)/0.65,0,1)*PI)
		var weight:=1.5 if int(pose.get("combo_step",1))==3 else 1.0
		_mount.position+=Vector2(pose.facing*thrust*3.5*weight,thrust*1.5)
