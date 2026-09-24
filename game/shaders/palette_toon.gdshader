shader_type spatial;
render_mode cull_disabled, specular_disabled;
// GLB vertex colours are linear. Compatibility shades into an sRGB framebuffer;
// convert here, since StandardMaterial's vertex sRGB flag only affects Vulkan.
void vertex() {
	if (OUTPUT_IS_SRGB) {
		COLOR.rgb = mix(12.92 * COLOR.rgb, 1.055 * pow(max(COLOR.rgb, vec3(0.0)), vec3(1.0/2.4)) - 0.055, step(vec3(0.0031308), COLOR.rgb));
	}
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
void light() {
	float n = dot(NORMAL, LIGHT);
	float band = n > 0.55 ? 1.0 : (n > 0.0 ? 0.78 : 0.38);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * band / PI;
}
