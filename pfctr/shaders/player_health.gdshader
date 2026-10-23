shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed = 0.0; // 0 = steady tint

void fragment() {
	float pulse = pulse_speed > 0.0 ? 0.6 + 0.4 * sin(TIME * pulse_speed) : 1.0;
	COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * tint_color.rgb, tint_amount * pulse);
}