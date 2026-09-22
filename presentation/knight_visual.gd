extends "res://presentation/fighter_visual.gd"
## New locomotion drawings are isolated from the editable combat animation resource.
const MotionFrames=preload("res://data/knight_motion_frames.tres")
@export var running_atlas: Texture2D=preload("res://art/characters/grounded-run-v001/run-armed.png")
@export var texture_overrides: Dictionary = {}
@export var moving_attack_atlas: Texture2D
@export var combo_motion: Resource
const EquipmentShader=preload("res://presentation/knight_equipment.gdshader")
var equipment_material: ShaderMaterial
const MountedSheet=preload("res://art/characters/mounted-v001/mounted.png")
const STRIDE_FRAMES: int=16
const STRIDE_COLUMNS: int=8
const UnarmedRun=preload("res://art/characters/grounded-run-v001/run-unarmed.png")
const IdleUnarmed=preload("res://art/characters/grounded-run-v001/idle-unarmed.png")
var _unarmed: Sprite2D
var _unarmed_frame: AtlasTexture=AtlasTexture.new()
var unarmed: bool=false
var breathing: bool=false
var breath_stop_remaining: float=0.0
const BREATH_RISE_SECONDS: float=0.35
var tired_walk: bool=false
var exertion: float=0.0
var _breath_weight: float=0.0
const SprintArmed=preload("res://art/characters/grounded-run-v001/sprint-armed.png")
const SprintUnarmed=preload("res://art/characters/grounded-run-v001/sprint-unarmed.png")
const WalkArmed=preload("res://art/characters/grounded-run-v001/walk-armed.png")
const WalkUnarmed=preload("res://art/characters/grounded-run-v001/walk-unarmed.png")
var _breath: Node2D=preload("res://presentation/knight_breath_view.gd").new()
var ceremony_age: float=-1.0
var _fatigue_weight: float=0.0
var _ceremony: Sprite2D=preload("res://presentation/knight_ceremony_view.gd").new()
var damage_serial: int=0
var _last_damage_serial: int=0
var fatigue: Sprite2D=preload("res://presentation/knight_fatigue_view.gd").new()
var mounted:=false
var _mount: Sprite2D
var _mount_frame:=AtlasTexture.new()
var weapon_tier:=0
var armor_tier:=0
var _gait_time:=0.0
@export_range(20,44,0.5) var walking_frame_rate: float=32.0
@export_range(32,60,0.5) var running_frame_rate: float=48.0
var _gait_rate: float=32.0
var _moving_attack: Sprite2D
var _moving_region:=AtlasTexture.new()
var _combo_attack: Sprite2D
var _combo_region:=AtlasTexture.new()
var _motion_time:=0.0
var _was_grounded:=true
var _landing:=0.0
func _init() -> void:
	add_child(fatigue)
	add_child(_ceremony)
	add_child(_breath)
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
		if clip==&"run" and running_atlas!=null:
			for index in range(STRIDE_FRAMES):
				var frame_texture: AtlasTexture=AtlasTexture.new()
				frame_texture.atlas=running_atlas
				frame_texture.region=Rect2((index%STRIDE_COLUMNS)*128,(index/STRIDE_COLUMNS)*96,128,96)
				sprite_frames.add_frame(clip,frame_texture)
			continue
		for index in range(MotionFrames.get_frame_count(clip)):
			var drawing=MotionFrames.get_frame_texture(clip,index)
			if clip==&"run" and drawing is AtlasTexture and running_atlas!=null:
				drawing=drawing.duplicate();drawing.atlas=running_atlas
			sprite_frames.add_frame(clip,drawing,MotionFrames.get_frame_duration(clip,index))
	_bind_stride(&"sprint",SprintArmed,16,8)
	_bind_stride(&"tired_walk",WalkArmed,16,8)

func _bind_stride(clip: StringName, atlas: Texture2D, count: int, columns: int) -> void:
	if sprite_frames.has_animation(clip):sprite_frames.remove_animation(clip)
	sprite_frames.add_animation(clip)
	for index: int in range(count):
		var drawing: AtlasTexture=AtlasTexture.new()
		drawing.atlas=atlas;drawing.region=Rect2((index%columns)*128,(index/columns)*96,128,96)
		sprite_frames.add_frame(clip,drawing)

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
	_hide_alternate_bodies()
	fatigue.reset()
	_fatigue_weight=0
	_breath_weight=0;_breath.visible=false
	ceremony_age=-1
	_ceremony.visible=false
	_motion_time=0
	_landing=0
	_was_grounded=true
	rotation=0
	scale=Vector2.ONE
func present(pose: Dictionary, seconds: float) -> void:
	_breath_weight=move_toward(_breath_weight,exertion,maxf(0,seconds)/0.85)
	_present_body(pose,seconds)
	_breath.present(_breath_weight,int(pose.facing),seconds,pose.alive and not hurt_active and pose.get("moving",false),mounted)
	var resting: bool=breathing and not pose.get("moving",false) and float(pose.get("attack_progress",1.0))>=1
	var safe_pose: bool=pose.alive and not hurt_active and not pose.get("dashing",false)
	var target: float=1.0 if resting and safe_pose else 0.0
	_fatigue_weight=move_toward(_fatigue_weight,target,maxf(0,seconds)/0.75)
	# Complete the rise while travel is still locked, never drag a resting body.
	if breath_stop_remaining>0:
		_fatigue_weight=minf(_fatigue_weight,breath_stop_remaining/BREATH_RISE_SECONDS)
	if not safe_pose or pose.get("moving",false):_fatigue_weight=0
	var ceremony: bool=ceremony_age>=0 and ceremony_age<2.4 and safe_pose and not pose.get("moving",false) and float(pose.get("attack_progress",1.0))>=1
	if ceremony:
		_fatigue_weight=0
		var blend: float=smoothstep(0,0.13,ceremony_age)*(1.0-smoothstep(2.12,2.4,ceremony_age))
		_dim_body(1.0-blend)
		_ceremony.present(ceremony_age,int(pose.facing))
		_ceremony.modulate.a=blend
	elif _fatigue_weight>0:
		var weight: float=smoothstep(0,1,_fatigue_weight)
		_dim_body(1.0-weight)
		# Cavalry has its own baked top-tier palette; do not recolour its horse.
		fatigue.material=_mount.material if mounted else equipment_material
		fatigue.present(unarmed,mounted,int(pose.facing),seconds)
		fatigue.modulate.a=weight
	else:fatigue.reset()

func _dim_body(alpha: float) -> void:
	self_modulate.a*=alpha
	for body in [_unarmed,_mount,_moving_attack,_combo_attack]:body.modulate.a=alpha

func _present_body(pose: Dictionary, seconds: float) -> void:
	var striding: bool=pose.get("moving",false) and pose.get("grounded",true) and not pose.get("dashing",false)
	if striding and seconds>0 and is_finite(seconds):
		var speed: float=absf(pose.get("horizontal_speed",190.0*float(pose.get("locomotion_rate",1.0))))
		var desired: float=lerpf(walking_frame_rate,running_frame_rate,smoothstep(165,322,speed))
		if tired_walk:desired=20.0
		_gait_rate=lerpf(_gait_rate,desired,1.0-exp(-seconds*12))
		_gait_time+=seconds*_gait_rate/12.0
	elif not striding and not pose.get("dashing",false):
		_gait_rate=walking_frame_rate
	if damage_serial>_last_damage_serial:_reaction.trigger(-float(pose.facing))
	_last_damage_serial=damage_serial
	super.present(pose,seconds)
	if equipment_material!=null:equipment_material.set_shader_parameter("facing",-1.0 if flip_h else 1.0)
	self_modulate=Color.WHITE
	_hide_alternate_bodies()
	_moving_attack.offset=Vector2.ZERO
	if mounted and pose.alive:
		_present_mount(pose,seconds)
		return
	_mount.visible=false
	_unarmed.visible=false
	if unarmed:
		_motion_time+=maxf(0,seconds)
		if not hurt_active and pose.alive:
			rotation=0;scale=Vector2.ONE;offset=Vector2.ZERO
		var running: bool=striding and pose.alive and not hurt_active
		var slow: bool=running and tired_walk
		var sprinting: bool=running and absf(pose.get("horizontal_speed",0.0))>240
		var count: int=16 if slow else STRIDE_FRAMES
		var drawing: int=int(fposmod(_gait_time*12,count)) if running else int(fposmod(_motion_time*3,4))
		var columns: int=8 if running else 2
		_unarmed_frame.atlas=WalkUnarmed if slow else SprintUnarmed if sprinting else UnarmedRun if running else IdleUnarmed
		_unarmed_frame.region=Rect2((drawing%columns)*128,(drawing/columns)*96,128,96)
		_unarmed.texture=_unarmed_frame;_unarmed.flip_h=pose.facing<0
		_unarmed.visible=true;self_modulate=Color(1,1,1,0)
		return
	if hurt_active or not pose.alive: return
	var gait:=int(fposmod(_gait_time*12,8)) # Legacy moving-slash sheet has eight rows.
	if animation==&"run":
		if tired_walk:animation=&"tired_walk"
		elif absf(pose.get("horizontal_speed",0.0))>240:animation=&"sprint"
		frame=_action_frame(animation,fposmod(_gait_time*12.0/sprite_frames.get_frame_count(animation),1.0))
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
	elif animation in [&"run",&"sprint",&"tired_walk"]:
		offset=Vector2.ZERO # Contact and airborne heights are already authored in the sheet.
	elif animation==&"attack":
		offset=Vector2.ZERO
	if _landing>0 and grounded:
		var amount:=sin(_landing/0.12*PI)*0.055
		scale=Vector2(1+amount,1-amount)
		offset.y+=amount*24

	if animation==&"attack" and combo_motion!=null and combo_motion.planted_atlas!=null:
		var step:=clampi(int(pose.get("combo_step",1)),1,3)
		var drawing: int=combo_motion.frame_at(step,float(pose.attack_progress))
		if (pose.get("attack_advancing",false) or striding) and combo_motion.moving_atlas!=null:
			_moving_region.atlas=combo_motion.moving_atlas
			var rows: int=combo_motion.moving_gait_rows
			_moving_region.region=Rect2(drawing*160,((step-1)*rows+gait%rows)*128,160,128)
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
		fatigue.material=equipment_material
		_unarmed.material=equipment_material
		_ceremony.material=equipment_material
	equipment_material.set_shader_parameter("weapon_tier",float(weapon_tier))
	equipment_material.set_shader_parameter("armor_tier",float(armor_tier))

func set_mounted(value: bool) -> void:
	# Equipment is state; only present/reset own which body is drawn.
	mounted=value

func _hide_alternate_bodies() -> void:
	for body in [_unarmed, _mount, _moving_attack, _combo_attack, fatigue, _ceremony]:
		body.visible=false
		body.modulate.a=1.0

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
	elif pose.get("moving",false) or pose.get("dashing",false):index=1+int(_gait_time*24/STRIDE_FRAMES)%2
	if hurt_active:index=0
	_mount_frame.atlas=MountedSheet
	_mount_frame.region=Rect2(index*160,0,160,128)
	_mount.texture=_mount_frame
	_mount.position=Vector2(0,-absf(sin(_gait_time*12/STRIDE_FRAMES*TAU*2))*1.0 if index in [1,2] else sin(_motion_time*2)*0.5)

	# Brace the horse through the cut, then ease back to a balanced stance.
	if progress<1 and not hurt_active:
		var thrust:=sin(clampf((progress-0.2)/0.65,0,1)*PI)
		var weight:=1.5 if int(pose.get("combo_step",1))==3 else 1.0
		var advance: float=thrust*3.5*weight if pose.get("attack_advancing",false) else 0.0
		_mount.position+=Vector2(pose.facing*advance,thrust*1.5)
