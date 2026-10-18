extends RefCounted
static func demo() -> bool:
 return ProjectSettings.get_setting("distribution/edition","full")=="demo"
static func accepts(restored: Dictionary) -> bool:
 return not demo() or (not restored.is_empty() and restored.session.core_loop.trial and not restored.has("journey"))
