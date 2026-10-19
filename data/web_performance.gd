class_name WebPerformance
extends Resource
## Web-only pacing. Phones get hot when the browser renders as fast as a 90-120 Hz screen
## allows, and whole decoded music tracks cost about 40 MB each in the page.
@export_range(0, 120, 1) var phone_fps: int = 30
@export_range(0, 240, 1) var desktop_fps: int = 60
## The simulation clock already runs at 30 ticks; at 60 physics ticks every other tick only
## re-prepares the same frame for the knight, view and HUD.
@export_range(0, 120, 1) var phone_physics_hz: int = 30
## Web music plays as a stream instead of a fully decoded sample. Effects stay samples.
@export var stream_music: bool = true

static func current_features() -> PackedStringArray:
	var tags: PackedStringArray = []
	for tag: String in ["web", "web_android", "web_ios", "pc", "mobile"]:
		if OS.has_feature(tag): tags.append(tag)
	return tags

## 0 keeps the engine default (vsync, no extra cap) for native builds.
func frame_cap(features: PackedStringArray) -> int:
	if not features.has("web"): return 0
	return phone_fps if features.has("web_android") or features.has("web_ios") else desktop_fps

## 0 keeps the project physics rate.
func physics_rate(features: PackedStringArray) -> int:
	return phone_physics_hz if features.has("web") and (features.has("web_android") or features.has("web_ios")) else 0

func music_playback(features: PackedStringArray) -> int:
	return AudioServer.PLAYBACK_TYPE_STREAM if stream_music and features.has("web") else AudioServer.PLAYBACK_TYPE_DEFAULT
