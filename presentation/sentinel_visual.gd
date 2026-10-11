extends "res://presentation/fighter_visual.gd"
## The standalone combat prototype uses the same unarmed creature as the campaign.
const Look = preload("res://data/enemy_cast.tres")
func _init() -> void:
	var appearance: EnemyAppearance=Look.grunt
	sprite_frames=SpriteFrames.new();sprite_frames.remove_animation(&"default")
	var clips: Dictionary={&"idle":appearance.walk,&"run":appearance.walk,&"windup":appearance.windup,&"attack":appearance.strike,&"hurt":appearance.hurt,&"death":appearance.fallen}
	for clip: StringName in clips:
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_speed(clip,appearance.idle_fps if clip==&"idle" else 10.0)
		sprite_frames.set_animation_loop(clip,clip in [&"idle",&"run"])
		for index: int in clips[clip]:
			var texture: AtlasTexture=AtlasTexture.new();texture.atlas=appearance.atlas;texture.region=appearance.region(index)
			sprite_frames.add_frame(clip,texture)
	animation=&"idle";texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _present_hit(pose: Dictionary, seconds: float) -> bool:
	if not pose.has("hp"):return false
	_reaction.duration=hurt_seconds;_reaction.distance=hurt_distance
	var hit: Dictionary=_reaction.observe(pose.hp,pose.get("shield",0),seconds,-float(pose.facing))
	hurt_active=hit.active;flip_h=pose.facing<0
	if not pose.alive:
		_death_age+=maxf(0,seconds)
		visible=true;animation=&"death";frame=mini(1,int(_death_age/0.2))
		rotation=0;scale=Vector2.ONE;offset=Vector2.ZERO
		modulate=Color(1,1,1,1-smoothstep(0.5,1.25,_death_age))
		return true
	_death_age=0
	if not hit.active:return false
	visible=true;animation=&"hurt";frame=mini(1,int(hit.progress*2))
	offset=hit.offset;rotation=0;scale=Vector2.ONE
	modulate=Color.WHITE.lerp(Color(2.7,2.5,2.1),hit.flash)
	return true
