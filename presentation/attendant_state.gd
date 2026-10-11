extends RefCounted
## Bounded, transient presentation memory; never attached to the campaign graph.
enum Mode { WORK, GREET, ACKNOWLEDGE, SERVICE, ALERT }
var mode: Mode=Mode.WORK
var age: float=0.0
var work_age: float=0.0
var facing: float=1.0
var frame: int=0
var frame_age: float=0.0
var visible: bool=false
var near: bool=false
var pending_greeting: bool=false
var notice: float=0.0
var cooldown: float=0.0
var safe_age: float=0.0
var service_value: int=0
## Read-only references to the last two visual events; bounded at one per kind.
var payment: Dictionary={}
var module_event: Dictionary={}
func enter(next: Mode, direction: float) -> void:
 mode=next;age=0.0;facing=direction
 if next==Mode.WORK:work_age=0.0
