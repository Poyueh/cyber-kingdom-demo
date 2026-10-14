shader_type canvas_item;
render_mode unshaded;
uniform float nebula_strength=0.7;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void fragment(){
 vec2 pixel=floor(UV/SCREEN_PIXEL_SIZE/3.0)*3.0*SCREEN_PIXEL_SIZE;
 vec2 p=pixel*vec2(8.0,5.0);
 float cloud=noise(p+vec2(TIME*0.006,0.0))*0.55+noise(p*2.1)*0.3+noise(p*4.3)*0.15;
 float band=exp(-pow((pixel.y-0.63+pixel.x*0.3+sin(pixel.x*5.0)*0.12)*4.0,2.0));
 vec3 base=mix(vec3(0.018,0.027,0.055),vec3(0.038,0.08,0.10),pixel.y);
 vec3 nebula=mix(vec3(0.10,0.13,0.25),vec3(0.08,0.27,0.29),noise(p*0.5));
 base+=nebula*pow(cloud,2.0)*band*nebula_strength*2.8;
 vec2 stars=floor(UV/SCREEN_PIXEL_SIZE/2.0);
 float seed=hash(stars);
 float star=step(0.998,seed)*(0.42+0.25*sin(TIME*0.7+seed*400.0));
 base+=mix(vec3(0.48,0.73,0.80),vec3(0.95,0.78,0.49),hash(stars+13.0))*star;
 COLOR=vec4(base,1.0);
}
