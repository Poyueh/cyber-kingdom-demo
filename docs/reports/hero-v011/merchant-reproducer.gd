extends SceneTree
const Merchant=preload("res://domain/crystal_merchant.gd")
var failures:int=0
func _initialize()->void:
 var config:Dictionary=load("res://data/campaign.tres").campaign_rules()
 var trader=Merchant.new(config,0,-8000,8000)
 trader.phase=Merchant.Phase.WAITING_PAYMENT;trader.x=-3000
 trader.advance(1,1,-3000,430,false)
 var before:Dictionary=trader.capture()
 trader.advance(1,1,-3000,430,false)
 check(trader.capture()==before,"same tick must not change moving pose")
 trader.x=3000;trader.dispatch(1)
 trader.advance(2,1,3000,430,false)
 check(trader.x>3000,"remote dispatch continues outward from payment position")
 print("Merchant repro failures: ",failures)
 quit(failures)
func check(ok:bool,label:String)->void:
 print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
