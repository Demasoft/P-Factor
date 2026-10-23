shader_type particles;

// ---------------------------------------------------------------
// Explosion: 6 shining debris + smoke trail behind each one.
//
// Particle layout (INDEX):
//   id   = INDEX % debris_count   -> which debris piece (0..5)
//   slot = INDEX / debris_count   -> 0 = the debris, 1..N = smoke puffs
//
// GPUParticles2D settings:
//   amount        = debris_count * (1 + smoke_per_debris)   (default 6 * 9 = 54)
//   lifetime      >= 1.5
//   one_shot      = true
//   explosiveness = 1.0
//   texture       = soft round texture (e.g. GradientTexture2D, radial)
// ---------------------------------------------------------------

group_uniforms general;
uniform int debris_count = 6;
uniform int smoke_per_debris = 8;
uniform float seed = 1.0;  // change from script for a different explosion each time

group_uniforms debris;
uniform float debris_speed_min = 260.0;
uniform float debris_speed_max = 380.0;
uniform float debris_drag = 1.6;
uniform vec2 gravity = vec2(0.0, 300.0);
uniform float debris_life = 0.9;
uniform float debris_size = 0.3;
uniform float angle_jitter = 0.6;
uniform float glow_intensity = 3.0;  // >1 = HDR, needs Glow enabled in WorldEnvironment
uniform vec4 debris_hot_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform vec4 debris_cool_color : source_color = vec4(1.0, 0.35, 0.05, 1.0);

group_uniforms smoke;
uniform float smoke_interval = 0.05;  // time between puffs along the debris path
uniform float smoke_life = 0.9;
uniform vec2 smoke_drift = vec2(0.0, -45.0);
uniform float smoke_start_size = 0.25;
uniform float smoke_end_size = 1.3;
uniform float smoke_max_alpha = 0.6;
uniform float smoke_scatter = 14.0;
uniform vec4 smoke_start_color : source_color = vec4(0.35, 0.3, 0.28, 1.0);
uniform vec4 smoke_end_color : source_color = vec4(0.12, 0.12, 0.12, 1.0);

float hash(float n) {
	return fract(sin(n * 127.1 + seed * 311.7) * 43758.5453);
}

// Position of a debris piece after time t (launch + drag + gravity)
vec2 debris_path(vec2 dir, float speed, float t) {
	float d = max(debris_drag, 0.001);
	return dir * speed * (1.0 - exp(-d * t)) / d + 0.5 * gravity * t * t;
}

mat4 make_transform(vec2 pos, float rot, float sc) {
	float c = cos(rot) * sc;
	float s = sin(rot) * sc;
	mat4 m = mat4(1.0);
	m[0].xy = vec2(c, s);
	m[1].xy = vec2(-s, c);
	m[3].xy = pos;
	return m;
}

void start() {
	CUSTOM = vec4(0.0);  // CUSTOM.y = elapsed time since the burst
	TRANSFORM = make_transform(vec2(0.0), 0.0, 0.0);
	COLOR = vec4(0.0);
}

void process() {
	int idx = int(INDEX);
	int count = max(debris_count, 1);
	int id = idx % count;
	int slot = idx / count;
	float fid = float(id);

	CUSTOM.y += DELTA;
	float t = CUSTOM.y;

	// Per-debris random values (shared by the debris and its smoke trail)
	float angle = TAU * fid / float(count) + (hash(fid + 1.0) - 0.5) * angle_jitter;
	float speed = mix(debris_speed_min, debris_speed_max, hash(fid + 17.0));
	vec2 dir = vec2(cos(angle), sin(angle));

	if (slot == 0) {
		// ---------------- Shining debris ----------------
		float k = clamp(t / debris_life, 0.0, 1.0);
		vec2 pos = debris_path(dir, speed, t);
		float rot = angle + t * (hash(fid + 33.0) - 0.5) * 20.0;
		float sc = debris_size * (1.0 - 0.7 * k);
		if (t > debris_life) sc = 0.0;

		float flicker = 0.8 + 0.2 * sin(t * 60.0 + fid * 2.0);
		vec3 col = mix(debris_hot_color.rgb, debris_cool_color.rgb, smoothstep(0.0, 0.8, k));
		COLOR = vec4(col * glow_intensity * flicker, 1.0 - smoothstep(0.7, 1.0, k));
		TRANSFORM = make_transform(pos, rot, sc);
	} else {
		// ---------------- Smoke puffs left behind the debris ----------------
		float spawn_time = float(slot) * smoke_interval;  // moment this puff is dropped
		float s = t - spawn_time;                          // puff age

		if (s < 0.0 || s > smoke_life) {
			TRANSFORM = make_transform(vec2(0.0), 0.0, 0.0);
			COLOR = vec4(0.0);
		} else {
			float k = s / smoke_life;
			vec2 scatter = (vec2(hash(float(idx) * 3.1), hash(float(idx) * 5.7)) - 0.5) * smoke_scatter;
			vec2 pos = debris_path(dir, speed, spawn_time) + scatter + smoke_drift * s;
			float sc = mix(smoke_start_size, smoke_end_size, sqrt(k));
			float rot = hash(float(idx) * 7.3) * TAU + s * 0.5;

			float alpha = smoothstep(0.0, 0.1, k) * (1.0 - k) * smoke_max_alpha;
			// older puffs (farther from the debris head) fade a bit more
			alpha *= 1.0 - 0.5 * float(slot) / float(max(smoke_per_debris, 1));

			COLOR = vec4(mix(smoke_start_color.rgb, smoke_end_color.rgb, k), alpha);
			TRANSFORM = make_transform(pos, rot, sc);
		}
	}
}
