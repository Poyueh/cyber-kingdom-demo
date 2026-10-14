shader_type canvas_item;
render_mode unshaded;
uniform int kind=0;
uniform vec4 tint:source_color=vec4(0.5,0.8,0.7,1.0);
uniform float phase=0.0;
uniform float discovered=1.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void fragment(){
 vec2 p=(floor(UV*54.0)+0.5)/54.0*2.0-1.0;
 p/=0.72;
 float radius=length(p);
 float halo=exp(-max(radius-1.0,0.0)*13.0)*0.32;
 vec3 color=tint.rgb*0.55;float alpha=radius<1.3?halo:0.0;
 // Thin, tilted debris rings around the storm and void worlds.
 if(kind>=5){vec2 r=vec2(p.x+p.y*0.8,p.y*3.1);float ring=abs(length(r)-1.29);if(ring<0.08){color=tint.rgb*0.65;alpha=0.65;}}
 if(radius<=1.0){
  vec3 normal=vec3(p,sqrt(max(0.0,1.0-dot(p,p))));
  float lon=atan(normal.x,normal.z)+phase;
  vec2 surface=vec2(sin(lon)*3.2,normal.y*3.8)+vec2(cos(lon)*1.7,float(kind)*13.0);
  float n=noise(surface)*0.6+noise(surface*2.6)*0.28+noise(surface*6.1)*0.12;
  vec3 land=mix(tint.rgb*0.42,tint.rgb*1.15,step(0.52,n));
  if(kind==0){land=mix(vec3(0.035,0.19,0.25),vec3(0.21,0.45,0.29),step(0.48,n));land=mix(land,vec3(0.48,0.64,0.37),step(0.64,n));}
  if(kind==1){float dunes=sin(normal.y*27.0+sin(lon*3.0)*2.0+n*4.0);land=mix(vec3(0.45,0.23,0.11),tint.rgb,step(-0.2,dunes));}
  if(kind==2){land=mix(vec3(0.18,0.4,0.53),vec3(0.72,0.87,0.88),step(0.45,n+abs(normal.y)*0.2));}
  if(kind==3){land=mix(vec3(0.11,0.19,0.16),vec3(0.44,0.53,0.23),step(0.49,n));}
  if(kind==4){land=mix(vec3(0.17,0.12,0.14),vec3(0.89,0.30,0.08),step(0.58,n));land=mix(land,vec3(1.0,0.62,0.2),step(0.66,n));}
  if(kind==5){float bands=sin(normal.y*29.0+n*5.0+sin(lon*2.0));land=mix(vec3(0.19,0.32,0.52),vec3(0.58,0.77,0.83),step(0.0,bands));}
  if(kind==6){land=mix(vec3(0.14,0.09,0.23),vec3(0.55,0.32,0.65),step(0.55,n));}
  float clouds=noise(surface*1.4+vec2(phase*0.15,1.0));
  if(kind!=4 && kind!=6){land=mix(land,vec3(0.80,0.86,0.82),step(0.68,clouds)*0.5);}
  float lighting=clamp(dot(normal,normalize(vec3(-0.65,-0.5,0.65))),0.0,1.0);
  color=land*(0.15+lighting*0.85);
  float rim=pow(1.0-normal.z,3.0)*0.45;
  color+=tint.rgb*rim;alpha=1.0;
 }
 COLOR=vec4(color*mix(0.52,1.0,discovered),alpha);
}
