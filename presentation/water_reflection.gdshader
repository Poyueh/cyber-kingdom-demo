shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float bank_uv = 0.65;
uniform float ground_uv = 0.60;
uniform float elapsed = 0.0;
uniform float strength = 0.68;
uniform vec4 water_color : source_color = vec4(0.05,0.15,0.23,1.0);
void fragment() {
 float depth = max(0.0, SCREEN_UV.y - bank_uv);
 float row = floor(depth / SCREEN_PIXEL_SIZE.y / 3.0);
 float drift = (sin(row * 0.71 + elapsed * 1.1) * 1.8 + sin(row * 0.19 - elapsed * 0.8)) * SCREEN_PIXEL_SIZE.x;
 vec2 source = vec2(clamp(SCREEN_UV.x + drift, 0.001, 0.999), clamp(ground_uv - depth * 1.35, 0.001, ground_uv));
 vec3 reflected = texture(screen_texture,source).rgb;
 float fade = strength * (1.0 - smoothstep(0.02,0.46,depth));
 vec3 ink = mix(water_color.rgb,reflected * vec3(0.74,0.90,0.96),fade);
 float glint = step(0.995, sin(row * 1.93 + floor(SCREEN_UV.x*34.0)*2.71 + elapsed*0.45));
 ink += glint * 0.035;
 COLOR = vec4(ink,1.0);
}
