extends Sprite2D
## Authored full-body weight transfer. Never delays input or moves the simulation.
var _clip: StringName=&""
var _age: float=0.0
var _duration: float=0.0
var _moving: bool=false
var _facing: int=1
var _origin_facing: int=1
var _initialized: bool=false
var _prior: Texture2D
var _entry: Texture2D
var _prior_flip: bool=false
var _entry_flip: bool=false
var _region: AtlasTexture=AtlasTexture.new()

func reset() -> void:
	visible=false
	_clip=&"";_age=0;_initialized=false;_moving=false
	_prior=null;_entry=null

func present(knight: AnimatedSprite2D, pose: Dictionary, seconds: float) -> void:
	visible=false
	var appearance: Resource=knight.appearance
	if appearance==null or appearance.locomotion_transition==null:return
	var moving: bool=pose.get("moving",false)
	var facing: int=int(pose.facing)
	var eligible: bool=pose.alive and not knight.hurt_active and not knight.mounted and pose.get("grounded",true) and not pose.get("dashing",false) and float(pose.get("attack_progress",1.0))>=1 and (knight.ceremony_age<0 or knight.ceremony_age>=2.4) and not knight.breathing
	if not eligible:
		reset();_moving=moving;_facing=facing
		return
	if not _initialized:
		_initialized=true;_facing=facing
	if seconds>0 and is_finite(seconds):
		if facing!=_facing:
			_begin(&"turn",appearance.turn_seconds,_facing)
		elif moving!=_moving:
			_begin(&"start" if moving else &"stop",appearance.start_seconds if moving else appearance.stop_seconds,facing)
		_moving=moving;_facing=facing
		_age+=seconds
	if _clip!=&"" and _age>=_duration:
		# The last authored pose is a contact, so the next cycle starts on that foot.
		if moving:knight._stride.phase=0.0
		_clip=&""
	if _clip!=&"":
		_draw_transition(knight,appearance)
	else:
		var body: Sprite2D=knight._unarmed if knight.unarmed else null
		_prior=body.texture.duplicate() if body!=null else knight.sprite_frames.get_frame_texture(knight.animation,knight.frame)
		_prior_flip=body.flip_h if body!=null else knight.flip_h

func _begin(clip: StringName, duration: float, facing: int) -> void:
	_clip=clip;_duration=duration;_age=0;_origin_facing=facing
	_entry=_prior;_entry_flip=_prior_flip

func _draw_transition(knight: AnimatedSprite2D, appearance: Resource) -> void:
	var count: int=8 if _clip==&"turn" else 4
	var index: int=mini(count-1,int(_age/_duration*count))
	var start: int=8 if _clip==&"turn" else 4 if _clip==&"stop" else 0
	_region.atlas=appearance.unarmed_locomotion_transition if knight.unarmed else appearance.locomotion_transition
	_region.region=Rect2((start+index)%4*128,(start+index)/4*96,128,96)
	texture=_region
	flip_h=_origin_facing<0
	if _clip==&"turn" and index==7 and not _moving:
		texture=knight.appearance.unarmed_idle if knight.unarmed else knight.sprite_frames.get_frame_texture(&"idle",0)
		if knight.unarmed:
			var idle: AtlasTexture=AtlasTexture.new();idle.atlas=texture;idle.region=Rect2(0,0,128,96);texture=idle
		flip_h=_facing<0
	if index==0 and _entry!=null:
		texture=_entry;flip_h=_entry_flip
	knight._dim_body(0.0)
	visible=true;modulate=Color.WHITE
	_prior=texture.duplicate();_prior_flip=flip_h
