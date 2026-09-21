extends RefCounted
## Disposable presentation state: never part of the wallet or save file.
var position: Vector2=Vector2.ZERO
var velocity: Vector2=Vector2.ZERO
var radius: float=7.0
var angle: float=0.0
var spin: float=0.0
var ink: Color=Color("69d9c3")
var age: float=0.0
var incoming: bool=true
var start: Vector2=Vector2.ZERO
