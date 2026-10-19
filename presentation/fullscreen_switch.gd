extends RefCounted
## One fullscreen switch for desktop and the web build.
## Browsers only enter fullscreen inside the player's own tap or click, but Godot handles a
## button a frame later. On the web the press therefore arms the page (web/fullscreen.js),
## and the release of that same gesture performs the switch.
static var _web_available: int = -1

static func available() -> bool:
	if OS.has_feature("web"):
		if _web_available < 0:
			_web_available = 1 if bool(JavaScriptBridge.eval("!!(window.CyberKingdomFullscreen && window.CyberKingdomFullscreen.available())", true)) else 0
		return _web_available == 1
	return OS.has_feature("pc")

static func request(window: Window) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.CyberKingdomFullscreen && window.CyberKingdomFullscreen.arm()", true)
		return
	var full := window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
	window.mode = Window.MODE_WINDOWED if full else Window.MODE_FULLSCREEN
