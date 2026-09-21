extends RefCounted
## One hold funds one project; released partial payments allow a short tap-to-resume window.
class Refund extends RefCounted:
 var key: String
 var x: float
 var remaining: float
 func _init(target: String, at: float, duration: float) -> void:
  key=target;x=at;remaining=duration

var target_key: String=""
var _down: bool=false
var _waiting_for_release: bool=false
var _remaining: float=0.0
var _period: float=0.0
var _initial_delay: float
var _interval: float
var _refund_seconds: float
var _target_x: float=0.0
var _refunds: Array[Refund]=[]

func _init(initial_delay: float=0.5, interval: float=0.28, refund_seconds: float=1.0) -> void:
 _initial_delay=maxf(0.2,initial_delay)
 _interval=maxf(0.1,interval)
 _refund_seconds=maxf(0.1,refund_seconds)

func step(seconds: float, held: bool, allowed: bool, session: RefCounted, x: float) -> bool:
 if seconds>0 and is_finite(seconds):_advance_refunds(seconds,session)
 if not held:
  _defer_refund(session)
  _down=false;_waiting_for_release=false;target_key=""
  return false
 if seconds<=0 or not is_finite(seconds):return false
 if not allowed:
  _defer_refund(session);_stop()
  return false
 if _waiting_for_release:return false
 if not _down:
  _down=true
  var choice: Dictionary=session.context(x)
  if session.life.enabled and (not choice.enabled or choice.id=="recruit"):
   _stop()
   return session.throw_crystal(x,session._player_y,session.hero.facing)
  if not choice.enabled:
   _stop();return false
  target_key=choice.key;_target_x=choice.x
  _refunds=_refunds.filter(func(refund: Refund)->bool:return refund.key!=target_key)
  return _invest(session,x,choice,_initial_delay)
 var choice: Dictionary=session.context_for_key(x,target_key)
 if not choice.enabled:
  _defer_refund(session);_stop()
  return false
 _remaining-=seconds
 if _remaining>0:return false
 return _invest(session,x,choice,_interval)

func _defer_refund(session: RefCounted) -> void:
 if target_key.is_empty() or not session.has_method("cancel_investment"):return
 if not session.life.enabled or not session.investments.has(target_key):return
 if _refunds.any(func(refund: Refund)->bool:return refund.key==target_key):return
 _refunds.append(Refund.new(target_key,_target_x,_refund_seconds))

func _advance_refunds(seconds: float, session: RefCounted) -> void:
 if _refunds.is_empty():return
 for refund in _refunds:
  refund.remaining-=seconds
  if refund.remaining<=0:session.cancel_investment(refund.key,refund.x)
 _refunds=_refunds.filter(func(refund: Refund)->bool:return refund.remaining>0)

func _invest(session: RefCounted, x: float, choice: Dictionary, next_delay: float) -> bool:
 if not session.interact(x,target_key):
  _defer_refund(session);_stop();return false
 if choice.cost<=0 or choice.paid+1>=choice.cost:_stop()
 else:_period=next_delay;_remaining=next_delay
 return true

func _stop() -> void:
 _down=true;_waiting_for_release=true;target_key=""

func cancel() -> void:
 _refunds.clear();_stop()

func progress() -> float:
 if target_key.is_empty() or _period<=0:return 0.0
 return clampf(1.0-_remaining/_period,0,1)
