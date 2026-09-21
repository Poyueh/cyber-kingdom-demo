shader_type canvas_item;
render_mode unshaded;
uniform vec4 sky_top : source_color;
uniform vec4 sky_horizon : source_color;
uniform vec4 world_light : source_color;
uniform float daylight;
uniform float warmth;
uniform float phase;
uniform bool night;
uniform float sun_radius;
void fragment() {
 vec4 original=texture(TEXTURE,UV);
 // The authored skyline uses magenta/violet for open sky, blue for silhouettes.
 bool open_sky=UV.y<0.27 && original.r>0.22 && original.r>original.g*0.94;
 vec3 terrain=original.rgb*world_light.rgb;
 terrain=mix(terrain,original.rgb*vec3(1.12,1.55,1.25)+vec3(0.015,0.025,0.015),daylight*0.8);
 vec3 sky=mix(sky_top.rgb,sky_horizon.rgb,clamp(UV.y/0.24,0.0,1.0));
 // Preserve the pixel clouds from the source texture rather than flattening it.
 float cloud=clamp((0.36-original.r)*5.0,0.0,0.7);
 sky*=1.0-cloud*0.28;
 vec2 pixel=floor(UV/TEXTURE_PIXEL_SIZE/2.0)*2.0;
 vec2 center=vec2(mix(0.08,0.92,phase),0.225-sin(phase*3.14159265)*0.175)/TEXTURE_PIXEL_SIZE;
 float radius=night ? sun_radius*0.65 : sun_radius;
 float distance_to_body=length(pixel-center);
 vec3 body=night ? vec3(0.72,0.84,0.89) : mix(vec3(1.0,0.93,0.65),vec3(1.0,0.64,0.34),warmth);
 float glow=(1.0-smoothstep(radius,radius*3.2,distance_to_body))*(night ? 0.10 : 0.23);
 sky=mix(sky,body,glow);
 if (distance_to_body<radius) sky=body;
 // A few stable pixel stars, never a scrolling screen-space particle field.
 vec2 cell=floor(pixel/vec2(39.0,29.0));
 float seed=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
 if (night && seed>0.72 && mod(pixel.x,39.0)<2.0 && mod(pixel.y,29.0)<2.0) sky=mix(sky,vec3(0.74,0.84,0.9),(1.0-warmth)*0.7);
 COLOR=vec4(open_sky ? sky : terrain,original.a);
}
