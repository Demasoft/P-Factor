shader_type canvas_item;

uniform float scale = 1.1;          // higher = smaller clouds
uniform float speed = 0.02;         // horizontal drift speed
uniform float transparency = 0.0;   // 0 = fully visible, 1 = invisible

const mat2 ROTATE = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));

vec2 hash(vec2 p)
{
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p)
{
	const float K1 = 0.366025404;
	const float K2 = 0.211324865;

	vec2 i = floor(p + (p.x + p.y) * K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;

	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 n = h * h * h * h * vec3(
		dot(a, hash(i)),
		dot(b, hash(i + o)),
		dot(c, hash(i + 1.0))
	);

	return dot(n, vec3(70.0));
}

// Layered noise: each octave is rotated and weighs less than the last.
float fbm(vec2 p, float weight, float decay, bool use_abs)
{
	float total = 0.0;
	for (int i = 0; i < 6; i++)
	{
		float n = noise(p);
		total += weight * (use_abs ? abs(n) : n);
		p = ROTATE * p;
		weight *= decay;
	}
	return total;
}

void fragment()
{
	vec2 uv = UV * scale;

	// Warp and scroll, shared by all layers
	float warp = fbm(uv * 0.5, 0.1, 0.4, false);
	vec2 offset = vec2(warp + TIME * speed, warp);
	offset.y = warp;

	// Cloud shape
	vec2 p = uv + offset;
	float edges = fbm(p, 0.8, 0.7, true);
	float body = fbm(p, 0.7, 0.6, false);
	float density = 0.2 + 8.0 * body * (edges + body) * edges;

	// Fine detail (warp is NOT scaled, same as the original)
	float detail = fbm(uv * 2.0 + offset, 0.4, 0.6, false)
	             + fbm(uv * 3.0 + offset, 0.4, 0.6, true);

	float mask = clamp(density + detail, 0.0, 1.0);

	// Original cloud color: warm white + a bit of the sky tint
	vec3 sky_tint = 0.5 * mix(vec3(0.015, 0.025, 0.08), vec3(0.05, 0.10, 0.25), UV.y);
	float brightness = clamp(0.5 + 0.3 * detail, 0.0, 1.0);
	vec3 colour = clamp(sky_tint + vec3(1.1, 1.1, 0.9) * brightness, 0.0, 1.0);

	COLOR = vec4(colour, mask * (1.0 - transparency));
}