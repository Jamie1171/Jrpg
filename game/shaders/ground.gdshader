shader_type spatial;
render_mode specular_disabled;
uniform bool forest = false;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float box_distance(vec2 p, vec2 center,vec2 half_size) {
	vec2 q=abs(p-center)-half_size;
	return length(max(q,vec2(0)))+min(max(q.x,q.y),0.0);
}
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	vec2 p=world_position.xz;
	float path;
	if(forest) {
		path=min(box_distance(p,vec2(0,5),vec2(2.8,20)),box_distance(p,vec2(4,-7),vec2(7,5)));
	} else {
		path=min(box_distance(p,vec2(0,0),vec2(4,30)),box_distance(p,vec2(1,4),vec2(17,2.9)));
		path=min(path,box_distance(p,vec2(-13,-1),vec2(3.8,4.5)));
	}
	float patches=noise(p*.7);
	float dirt=1.0-smoothstep(-.5,.5,path+(patches-.5)*1.6);
	vec3 grass=mix(vec3(.34,.47,.24),vec3(.47,.58,.31),noise(p*.25));
	vec3 earth=mix(vec3(.63,.53,.36),vec3(.71,.61,.44),patches);
	ALBEDO=mix(grass,earth,dirt)*(0.96+0.06*noise(p*12.0));
	ROUGHNESS=1.0;
}
