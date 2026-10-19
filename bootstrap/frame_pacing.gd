extends Node
## Applies the web frame cap once at startup; native builds keep vsync.
## The cap runs in the page (web/frame-pacing.js): Engine.max_fps busy-waits on the web.
func _ready() -> void:
	if not OS.has_feature("web"): return
	var profile: Resource = load("res://data/web_performance.tres")
	var features: PackedStringArray = WebPerformance.current_features()
	var physics: int = profile.physics_rate(features)
	if physics > 0: Engine.physics_ticks_per_second = physics
	JavaScriptBridge.eval("window.CyberKingdomFrames && window.CyberKingdomFrames.cap(%d)" % profile.frame_cap(features), true)
