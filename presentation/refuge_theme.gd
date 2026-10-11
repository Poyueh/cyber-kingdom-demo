extends RefCounted
## One restrained visual language for title, modal panels and touch controls.
const INK: Color=Color("0c171ff5")
const EDGE: Color=Color("526467")
const GOLD: Color=Color("c5ac78")
const TEXT: Color=Color("e5e5d8")
const CYAN: Color=Color("8fcac1")
static func plate(fill: Color=INK, edge: Color=EDGE, padding: int=12) -> StyleBoxFlat:
 var style: StyleBoxFlat=StyleBoxFlat.new()
 style.bg_color=fill;style.border_color=edge
 style.set_border_width_all(1);style.set_corner_radius_all(5)
 style.set_content_margin_all(padding)
 style.shadow_color=Color(0,0,0,0.28);style.shadow_size=5;style.shadow_offset=Vector2(0,3)
 return style
static func make() -> Theme:
 var result: Theme=Theme.new()
 result.default_font=preload("res://presentation/localized_font.gd").current()
 result.default_font_size=16
 for type: StringName in [&"Button",&"OptionButton"]:
  result.set_stylebox("normal",type,plate(Color("14232ce8"),Color("42585d")))
  result.set_stylebox("hover",type,plate(Color("24393cf5"),GOLD))
  result.set_stylebox("pressed",type,plate(Color("30433e"),CYAN))
  result.set_stylebox("disabled",type,plate(Color("101b23cc"),Color("2a383e")))
  var focus: StyleBoxFlat=plate(Color.TRANSPARENT,GOLD,0)
  focus.shadow_size=0;focus.set_border_width_all(2)
  result.set_stylebox("focus",type,focus)
  result.set_color("font_color",type,TEXT)
  result.set_color("font_hover_color",type,Color("fff0ce"))
  result.set_color("font_pressed_color",type,Color("e1fff5"))
  result.set_color("font_disabled_color",type,Color("6e858c"))
  result.set_color("icon_normal_color",type,Color("cbd7cd"))
 result.set_stylebox("panel","PanelContainer",plate(INK,EDGE,20))
 result.set_stylebox("panel","PopupMenu",plate(INK,EDGE,8))
 result.set_stylebox("hover","PopupMenu",plate(Color("29413e"),GOLD,8))
 result.set_color("font_color","Label",TEXT)
 var line: StyleBoxLine=StyleBoxLine.new();line.color=Color("485955");line.thickness=1
 result.set_stylebox("separator","HSeparator",line)
 var track: StyleBoxFlat=plate(Color("060e14"),Color("35494b"),0);track.content_margin_top=3;track.content_margin_bottom=3
 result.set_stylebox("slider","HSlider",track)
 result.set_stylebox("grabber_area","HSlider",plate(Color("627e77"),Color("627e77"),0))
 result.set_stylebox("grabber_area_highlight","HSlider",plate(GOLD,GOLD,0))
 return result
static func touch_texture(key: String, side: int, glyph_size: int, pressed: bool=false) -> Texture2D:
 var image: Image=Image.create(side,side,false,Image.FORMAT_RGBA8)
 image.fill(Color.TRANSPARENT)
 var center: Vector2=Vector2.ONE*(side-1)*0.5
 var radius: float=side*0.46
 for y: int in range(side):
  for x: int in range(side):
   var distance: float=Vector2(x,y).distance_to(center)
   if distance>radius:continue
   var tint: Color=Color("243d3be8") if pressed else Color("101e28b8")
   if distance>radius-1.5:tint=CYAN if pressed else Color("9e9b7ea0")
   elif distance>radius-5 and distance<radius-4:tint=Color("62807966")
   image.set_pixel(x,y,tint)
 var glyph: Image=preload("res://presentation/ui_icons.gd").get_icon(key).get_image()
 glyph.resize(glyph_size,glyph_size,Image.INTERPOLATE_LANCZOS)
 var inset: int=(side-glyph_size)/2
 image.blend_rect(glyph,Rect2i(0,0,glyph_size,glyph_size),Vector2i(inset,inset))
 return ImageTexture.create_from_image(image)
