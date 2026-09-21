extends RefCounted
## Facility staff are visual inhabitants; never fabricated workers or extra economy.
const PEOPLE=preload("res://art/characters/resident-motion-v002/residents.png")
const ROLES: Dictionary={"hall":1,"workshop":5,"hunt_tools":3,"farm_tools":2,"drill":5,"armory":4}
static func draw_on(view: Node2D, sim: RefCounted, hero_x: float) -> void:
 if sim.frontier.city_level==0:return
 for site: String in ROLES:
  if not sim.site_visible(site):continue
  if site not in ["hall","drill"] and not sim.built.get(site,false):continue
  var x: float=sim.world.sites[site]+(69 if site!="hall" else -65)
  if not view._on_screen(x,65):continue
  var threatened: bool=sim.raiders.any(func(e: Dictionary):return e.fighter.is_alive() and absf(e.x-x)<180)
  if threatened:continue # Staff take shelter; they do not act as free soldiers.
  var time: float=sim.workforce.elapsed
  var frame: int=int(time*3.5+ROLES[site])%8
  var row: int=ROLES[site]*2+1
  var facing: float= -1.0 if hero_x<x else 1.0
  view.draw_set_transform(Vector2(x,430),0,Vector2(facing,1.0+sin(time*2+x)*0.007))
  preload("res://presentation/compact_people.gd").draw(view,PEOPLE,Rect2(frame*64,row*64,64,64),Color("b9d0c5"))
 view.draw_set_transform(Vector2.ZERO)
