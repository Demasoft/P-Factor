shader_type particles;

uniform float speed_min = 20.0;
uniform float speed_max = 40.0;
uniform float spread_deg = 25.0;
uniform vec2 emission_size = vec2(8.0, 8.0);
uniform vec2 wind = vec2(-15.0, -15.0);   // acceleration in px/s², negative Y = rises
uniform float damping = 1.2;               // how fast puffs slow down
uniform float spin = 0.6;                  // rotation speed (radians/s)
uniform float start_scale = 0.4;
uniform float end_scale = 1.6;
uniform float max_alpha = 0.55;
uniform vec3 start_color : source_color = vec3(0.45);
uniform vec3 end_color : source_color = vec3(0.12);

float hash(uint x) {
	x = ((x >> 16u) ^ x) * 73244475u;
	x = ((x >> 16u) ^ x) * 73244475u;
	x = (x >> 16u) ^ x;
	return float(x) / 4294967295.0;
}

void start() {
	uint seed = NUMBER * 747796405u + RANDOM_SEED;

	// Random direction inside a cone pointing up
	float a = radians((hash(seed) - 0.5) * 2.0 * spread_deg);
	float spd = mix(speed_min, speed_max, hash(seed + 1u));
	vec3 vel = vec3(sin(a), -cos(a), 0.0) * spd;

	// Random spawn position inside the emission box
	vec2 offset = (vec2(hash(seed + 4u), hash(seed + 5u)) - 0.5) * emission_size;

	TRANSFORM = mat4(1.0);
	TRANSFORM[3].xy = offset;

	// Needed because the particles use world coordinates (Local Coords off)
	TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	VELOCITY = (EMISSION_TRANSFORM * vec4(vel, 0.0)).xyz;

	CUSTOM.x = (hash(seed + 2u) - 0.5) * TAU;       // rotation angle
	CUSTOM.y = 0.0;                                  // age, 0 to 1
	CUSTOM.z = mix(0.7, 1.3, hash(seed + 3u));      // per-puff size variation
	COLOR = vec4(0.0);
}

void process() {
	float t = CUSTOM.y + DELTA / LIFETIME;
	CUSTOM.y = t;

	if (t >= 1.0) {
		ACTIVE = false;
	} else {
		// Motion
		VELOCITY += vec3(wind, 0.0) * DELTA;
		VELOCITY *= max(0.0, 1.0 - damping * DELTA);
		TRANSFORM[3].xyz += VELOCITY * DELTA;

		// Rotation and growth
		CUSTOM.x += spin * DELTA;
		float s = mix(start_scale, end_scale, t) * CUSTOM.z;
		float c = cos(CUSTOM.x);
		float sn = sin(CUSTOM.x);
		TRANSFORM[0] = vec4(c * s, sn * s, 0.0, 0.0);
		TRANSFORM[1] = vec4(-sn * s, c * s, 0.0, 0.0);
		TRANSFORM[2] = vec4(0.0, 0.0, 1.0, 0.0);

		// Quick fade in, long fade out, light gray turning dark
		float alpha = smoothstep(0.0, 0.15, t) * (1.0 - t) * max_alpha;
		COLOR = vec4(mix(start_color, end_color, t), alpha);
	}
}