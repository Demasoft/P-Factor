shader_type canvas_item;
render_mode blend_premul_alpha;

varying float glow;

void vertex() {
	glow = INSTANCE_CUSTOM.w;
}

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float soft = clamp(1.0 - d, 0.0, 1.0);
	soft = soft * soft * (3.0 - 2.0 * soft);
	float a = COLOR.a * soft;
	// premultiplied: alpha 0 with color > 0 = additive, alpha > 0 = normal blend
	COLOR = vec4(COLOR.rgb * a, a * (1.0 - glow));
}