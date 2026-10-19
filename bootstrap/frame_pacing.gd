extends Node
## Applies the web frame cap once at startup; native builds keep vsync.
func _ready() -> void:
	Engine.max_fps = load("res://data/web_performance.tres").frame_cap(WebPerformance.current_features())
