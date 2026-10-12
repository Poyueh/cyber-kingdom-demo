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
uniform vec2 sky_size;
uniform float halo_strength;
uniform float halo_extent;
uniform bool layered_biome = false;
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
 // Measure both axes in world pixels; the background may stretch independently.
 float radius=sun_radius*sky_size.y*TEXTURE_PIXEL_SIZE.y*(night ? 0.65 : 1.0);
 vec2 center=vec2(mix(0.08,0.92,phase),0.225-sin(phase*3.14159265)*0.175)*sky_size;
 center.y=max(center.y,radius+2.0);
 vec2 body_pixel=(floor((UV*sky_size-center)/2.0)+0.5)*2.0;
 float distance_to_body=length(body_pixel);
 vec3 body=night ? vec3(0.72,0.84,0.89) : mix(vec3(1.0,0.93,0.65),vec3(1.0,0.64,0.34),warmth);
 // Fade at both horizons so sun/moon switching cannot flash a new disc.
 float visibility=smoothstep(0.0,0.1,phase)*(1.0-smoothstep(0.9,1.0,phase));
 // A few stable pixel stars, never a scrolling screen-space particle field.
 vec2 cell=floor(pixel/vec2(39.0,29.0));
 float seed=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
 if (night && seed>0.72 && mod(pixel.x,39.0)<2.0 && mod(pixel.y,29.0)<2.0) sky=mix(sky,vec3(0.74,0.84,0.9),(1.0-warmth)*visibility*0.7);
 float sky_weight=open_sky ? 1.0 : 0.0;
 if (layered_biome) {
  sky_weight=(1.0-smoothstep(0.14,0.42,UV.y))*smoothstep(0.14,0.30,original.r)*smoothstep(0.88,1.08,original.r/max(original.g,0.01));
 }
 vec3 result=mix(terrain,sky,sky_weight);
 // Ordered, world-pixel dithering keeps the halo soft without a smooth HD blur.
 vec2 grid=floor((UV*sky_size-center)/2.0);
 float dither=mod(grid.x+grid.y*2.0,4.0)/4.0;
 float radial=distance_to_body/max(radius,1.0);
 float halo=pow(1.0-smoothstep(0.6,halo_extent,radial),2.0);
 halo=floor(halo*24.0+dither)/24.0;
 float atmosphere=(1.0-smoothstep(0.24,0.45,UV.y))*mix(0.45,1.0,sky_weight);
 vec3 halo_color=mix(sky_horizon.rgb,body,night ? 0.48 : 0.7);
 result=mix(result,halo_color,halo*halo_strength*visibility*atmosphere);
 // A narrow pixel rim shares sky/cloud colour; the circular silhouette stays whole.
 float rim=floor(smoothstep(0.12,1.0,radial)*5.0)/5.0;
 vec3 core=night ? vec3(0.78,0.85,0.92) : mix(vec3(1.0,0.97,0.78),body,warmth*0.6);
 vec3 disc=mix(core,mix(body,sky_horizon.rgb,0.24),rim*0.7);
 if (night) {
  vec2 patch=floor(body_pixel/4.0);
  float grain=fract(sin(dot(patch,vec2(12.9898,78.233)))*43758.5453);
  disc*=1.0-step(0.72,grain)*0.065;
 }
 float edge=1.0-smoothstep(radius-2.0,radius+1.0,distance_to_body);
 edge=floor(edge*4.0+dither)/4.0;
 float opacity=(night ? 0.88 : 0.94)*(1.0-cloud*0.12)*visibility;
 result=mix(result,disc,edge*opacity);
 COLOR=vec4(result,original.a);
}
