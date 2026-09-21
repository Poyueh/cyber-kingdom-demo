shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float elapsed=0.0;
uniform float camera_x=0.0;
uniform float daylight=1.0;
uniform float intensity=0.065;
void fragment(){
 float axis=UV.x+UV.y*0.31+camera_x*0.00018;
 float soft=pow(max(0.0,sin(axis*19.0+sin(elapsed*0.12)*0.15)),16.0);
 float thin=pow(max(0.0,sin(axis*53.0+0.7)),48.0)*0.35;
 float fade=smoothstep(1.0,0.0,UV.y)*(0.75+sin(elapsed*0.5+axis*21.0)*0.15);
 vec3 ink=mix(vec3(0.38,0.62,0.88),vec3(1.0,0.84,0.48),daylight);
 COLOR=vec4(ink,(soft+thin)*fade*intensity*mix(0.32,1.0,daylight));
}
