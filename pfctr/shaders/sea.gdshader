shader_type canvas_item;

// Sea water (animated Voronoi) for Polygon2D.
// Uses the vertex position instead of UV, so no UV setup is needed.

// ---------- Polygon bounds (local coordinates) ----------
// Set these to the bounding box of your polygon points,
// or let the helper script (polygon_water.gd) set them automatically.
uniform vec2 poly_origin = vec2(-300.0, -150.0); // top-left of bounding box
uniform vec2 poly_size = vec2(600.0, 300.0);     // width and height of bounding box

// ---------- Colors ----------
uniform vec4 deep_color : source_color = vec4(0.02, 0.18, 0.35, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.10, 0.55, 0.70, 1.0);
uniform vec4 caustic_color : source_color = vec4(0.75, 0.95, 1.0, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// ---------- Voronoi ----------
uniform float cell_scale = 6.0;
uniform float cell_speed = 0.4;
uniform float edge_width = 0.12;
uniform float caustic_strength = 0.9;
uniform float foam_threshold = 0.85;
uniform float foam_strength = 0.35;

// ---------- Waves / distortion ----------
uniform float wave_amount = 0.03;
uniform float wave_frequency = 6.0;
uniform float wave_speed = 0.8;
uniform vec2 flow_direction = vec2(0.05, 0.02);

// ---------- Trapezoid perspective (optional) ----------
// top_width_ratio = top edge width / bottom edge width of your trapezoid.
// 1.0 = no horizontal squeeze. Cells also get shorter toward the top.
uniform float top_width_ratio : hint_range(0.05, 1.0) = 0.4;
uniform float perspective_strength : hint_range(0.0, 1.0) = 0.6;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

// Returns vec3(F1 distance, F2 distance, cell random value)
vec3 voronoi(vec2 uv, float t) {
	vec2 g = floor(uv);
	vec2 f = fract(uv);
	float f1 = 8.0;
	float f2 = 8.0;
	float id = 0.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = vec2(float(x), float(y));
			vec2 rnd = hash22(g + cell);
			vec2 point = 0.5 + 0.5 * sin(t + 6.2831 * rnd);
			float d = length(cell + point - f);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				id = rnd.x;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return vec3(f1, f2, id);
}

void fragment() {
	// 0..1 across the polygon's bounding box (y = 0 at top, 1 at bottom)
	vec2 nuv = (local_pos - poly_origin) / poly_size;

	// Perspective: undo the horizontal squeeze per row, shorten cells at the top
	float width_at_y = mix(top_width_ratio, 1.0, clamp(nuv.y, 0.0, 1.0));
	float u = (nuv.x - 0.5) / width_at_y + 0.5;
	float v = mix(nuv.y, nuv.y * nuv.y, perspective_strength);

	vec2 aspect = vec2(poly_size.x / poly_size.y, 1.0);
	vec2 uv = vec2(u, v) * aspect;

	// Flow + sine wobble
	uv += flow_direction * TIME;
	uv += vec2(
		sin(uv.y * wave_frequency + TIME * wave_speed),
		cos(uv.x * wave_frequency * 0.8 + TIME * wave_speed * 1.2)
	) * wave_amount;

	// Two Voronoi layers
	vec3 v1 = voronoi(uv * cell_scale, TIME * cell_speed);
	vec3 v2 = voronoi(uv * cell_scale * 1.9 + 17.0, -TIME * cell_speed * 1.3);

	// Base color
	float depth = mix(v1.z, 1.0 - v1.x, 0.5);
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, depth);

	// Caustic lines on Voronoi edges
	float e1 = 1.0 - smoothstep(0.0, edge_width, v1.y - v1.x);
	float e2 = 1.0 - smoothstep(0.0, edge_width * 0.8, v2.y - v2.x);
	float caustics = clamp(e1 * 0.7 + e2 * 0.5, 0.0, 1.0);
	col += caustic_color.rgb * caustics * caustic_strength;

	// Foam sparkles
	float foam = smoothstep(foam_threshold, 1.0, e1 * e2 + (1.0 - v2.x) * e1 * 0.5);
	col = mix(col, foam_color.rgb, foam * foam_strength);

	// Polygon2D's shape handles clipping, so alpha stays 1.
	COLOR = vec4(col, 1.0);
}
