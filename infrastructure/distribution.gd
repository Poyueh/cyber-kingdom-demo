extends RefCounted
static func demo() -> bool:
 return ProjectSettings.get_setting("distribution/edition","full")=="demo"
static func accepts(restored: Dictionary) -> bool:
 if not demo():return true
 if restored.is_empty() or restored.has("journey"):return false
 return restored.session.core_loop.trial or restored.session.core_loop.contained
