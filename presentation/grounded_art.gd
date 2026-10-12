extends RefCounted
## Transparent bottom padding must not lift the visible feet/root off the ground.
static var _padding: Dictionary={}
static func anchor(texture: Texture2D, at: Vector2, scale: float=1.0) -> Vector2:
 var key:=texture.get_instance_id()
 if not _padding.has(key):
  var image:=texture.get_image()
  var bounds:=image.get_used_rect() if image!=null else Rect2i()
  _padding[key]=texture.get_height()-bounds.end.y if bounds.has_area() else 0
 return at+Vector2(0,_padding[key]*scale)

## Atlas frames need their own visible bottom: construction stages differ.
static var _frame_bottom: Dictionary={}
static func frame_rect(texture: Texture2D, source: Rect2i, at: Vector2) -> Rect2:
 var key:=str(texture.get_instance_id())+":"+str(source)
 if not _frame_bottom.has(key):
  var image:=texture.get_image()
  var bounds:=image.get_region(source).get_used_rect() if image!=null else Rect2i()
  _frame_bottom[key]=bounds.end.y if bounds.has_area() else source.size.y
 return Rect2(at-Vector2(source.size.x*0.5,_frame_bottom[key]),Vector2(source.size))
