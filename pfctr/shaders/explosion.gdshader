shader_type particles;

uniform int seed = 0;                    // randomized per explosion by the script
uniform float spread = 2.8;              // debris cone width (radians), TAU = all directions
uniform float debris_speed_min = 260.0;
uniform float debris_speed_max = 680.0;
uniform float gravity = 700.0;

// ---- particle pools (draw order = index order, so smoke is behind, flash is on top)
const int SMOKE_N   = 140;
const int TRAIL_PER = 48;                // trail puffs per debris piece
const int DEBRIS_N  = 14;
const int FIRE_N    = 48;
const int SPARK_N   = 80;
const int FLASH_N   = 2;

const int SMOKE_0  = 0;
const int TRAIL_0  = SMOKE_0 + SMOKE_N;
const int FIRE_0   = TRAIL_0 + DEBRIS_N * TRAIL_PER;
const int DEBRIS_0 = FIRE_0 + FIRE_N;
const int SPARK_0  = DEBRIS_0 + DEBRIS_N;
const int FLASH_0  = SPARK_0 + SPARK_N;
// TOTAL = 956  -> set GPUParticles2D.amount to this

float rnd(int id, int k) {
	uint n = uint(id) * 9781u + uint(k) * 6271u + uint(seed) * 1013904223u + 1u;
	n = n * 747796405u + 2891336453u;
	n = ((n >> ((n >> 28u) + 4u)) ^ n) * 277803737u;
	n = (n >> 22u) ^ n;
	return float(n) / 4294967295.0;
}

mat4 xf(vec2 p, float ang, vec2 s) {
	float c = cos(ang);
	float sn = sin(ang);
	return mat4(
		vec4(c * s.x, sn * s.x, 0.0, 0.0),
		vec4(-sn * s.y, c * s.y, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(p, 0.0, 1.0));
}

// position under linear drag k and constant acceleration g (y axis)
vec2 ballistic(float t, vec2 v0, float k, float g) {
	float e = (1.0 - exp(-k * t)) / k;
	return v0 * e + vec2(0.0, g) * 0.5 * t * t;
}

void debris_params(int d, out vec2 v0, out float k, out float life) {
	float a = -1.5708 + (rnd(d, 0) - 0.5) * spread;      // biased upward
	float sp = mix(debris_speed_min, debris_speed_max, rnd(d, 1));
	v0 = vec2(cos(a), sin(a)) * sp;
	k = mix(0.2, 0.7, rnd(d, 2));
	life = mix(1.6, 2.4, rnd(d, 3));
}

void start() {
	CUSTOM = vec4(0.0);                  // x = age, w = glow (read by the draw shader)
}

void process() {
	CUSTOM.x += DELTA;
	float t = CUSTOM.x;
	int i = int(INDEX);

	vec2 pos = vec2(0.0);
	float ang = 0.0;
	vec2 sc = vec2(0.0);                 // zero scale = hidden
	vec4 col = vec4(0.0);
	float glow = 0.0;

	if (i < TRAIL_0) {
		// ------------------------------------------------ LINGERING SMOKE
		int s = i - SMOKE_0;
		// sqrt biases the spawn delay towards the END of the effect
		float delay = sqrt(rnd(s, 0)) * 2.0;
		float life = mix(2.0, 3.2, rnd(s, 1));
		float age = t - delay;
		float a = age / life;
		if (age >= 0.0 && a < 1.0) {
			float a0 = rnd(s, 2) * TAU;
			float r = 45.0 * sqrt(rnd(s, 3));
			vec2 start_p = vec2(cos(a0), sin(a0)) * r;
			float a1 = rnd(s, 4) * TAU;
			vec2 v0 = vec2(cos(a1), sin(a1)) * mix(15.0, 75.0, rnd(s, 5));
			pos = start_p + ballistic(age, v0, 1.2, 0.0);
			pos.y -= 30.0 * age;                                       // rises
			pos.x += sin(age * 1.8 + rnd(s, 6) * TAU) * 14.0 * age;    // wobble
			float size = mix(1.4, 2.6, rnd(s, 7)) * mix(0.5, 1.7, a);
			sc = vec2(size);
			ang = rnd(s, 8) * TAU;
			vec3 gray = vec3(mix(0.24, 0.12, a));
			vec3 warm = vec3(0.55, 0.25, 0.08);
			col.rgb = mix(gray, warm, exp(-age * 3.0) * 0.5);
			col.a = smoothstep(0.0, 0.12, a) * pow(1.0 - a, 1.5) * 0.6;
		}
	}
	else if (i < FIRE_0) {
		// ------------------------------------------------ DEBRIS TRAIL (fire -> smoke)
		int tr = i - TRAIL_0;
		int d = tr / TRAIL_PER;
		int k = tr % TRAIL_PER;
		vec2 v0; float kd; float dlife;
		debris_params(d, v0, kd, dlife);

		float ts = (float(k) + rnd(tr, 0)) / float(TRAIL_PER) * dlife * 0.92; // birth time
		float age = t - ts;
		float life = mix(1.2, 2.2, rnd(tr, 1));
		float a = age / life;
		if (age >= 0.0 && a < 1.0) {
			vec2 anchor = ballistic(ts, v0, kd, gravity);   // where the debris WAS
			vec2 drift = (vec2(rnd(tr, 2), rnd(tr, 3)) - 0.5) * 40.0 * age;
			pos = anchor + drift;
			pos.y -= 18.0 * age + 10.0 * age * age;                          // smoke buoyancy
			pos.x += sin(age * 3.0 + rnd(tr, 4) * TAU) * 10.0 * age;
			float size = mix(0.25, 0.5, rnd(tr, 5)) * (1.0 + a * 4.0);       // puff expands
			sc = vec2(size);
			ang = rnd(tr, 6) * TAU;

			float hot = 1.0 - smoothstep(0.0, 0.3, a);
			vec3 gray = vec3(mix(0.28, 0.1, a));
			vec3 fire = mix(vec3(1.0, 0.45, 0.08), vec3(1.0, 0.85, 0.4), 1.0 - smoothstep(0.0, 0.08, a));
			col.rgb = mix(gray, fire, hot);
			col.a = smoothstep(0.0, 0.04, a) * pow(1.0 - a, 1.5) * mix(0.5, 0.9, hot);
			glow = hot;                                                      // glowing near the debris
		}
	}
	else if (i < DEBRIS_0) {
		// ------------------------------------------------ FIREBALL
		int f = i - FIRE_0;
		float life = mix(0.45, 0.9, rnd(f, 0));
		float a = t / life;
		if (a < 1.0) {
			float a0 = rnd(f, 1) * TAU;
			vec2 start_p = vec2(cos(a0), sin(a0)) * 10.0 * rnd(f, 2);
			float a1 = rnd(f, 3) * TAU;
			vec2 v0 = vec2(cos(a1), sin(a1)) * mix(40.0, 230.0, rnd(f, 4));
			pos = start_p + ballistic(t, v0, 3.0, -90.0);
			float size = mix(1.2, 2.4, rnd(f, 5)) * (0.6 + 0.8 * smoothstep(0.0, 0.3, a)) * (1.0 - 0.6 * a);
			sc = vec2(size);
			ang = rnd(f, 6) * TAU;
			vec3 c = mix(vec3(1.0, 0.95, 0.6), vec3(1.0, 0.5, 0.1), smoothstep(0.0, 0.3, a));
			c = mix(c, vec3(0.5, 0.1, 0.03), smoothstep(0.3, 0.8, a));
			col = vec4(c, pow(1.0 - a, 1.2));
			glow = 1.0 - smoothstep(0.4, 0.9, a);
		}
	}
	else if (i < SPARK_0) {
		// ------------------------------------------------ BURNING DEBRIS (the chunks)
		int d = i - DEBRIS_0;
		vec2 v0; float kd; float dlife;
		debris_params(d, v0, kd, dlife);
		float a = t / dlife;
		if (a < 1.0) {
			pos = ballistic(t, v0, kd, gravity);
			ang = t * mix(-12.0, 12.0, rnd(d, 4));
			float size = mix(0.18, 0.32, rnd(d, 5));
			sc = vec2(size);
			vec3 c = mix(vec3(1.0, 0.8, 0.35), vec3(0.9, 0.25, 0.04), smoothstep(0.0, 0.5, a));
			c = mix(c, vec3(0.12, 0.05, 0.04), smoothstep(0.5, 1.0, a));    // cools to charred
			col = vec4(c, 1.0 - smoothstep(0.75, 1.0, a));
			glow = 0.8 * (1.0 - smoothstep(0.3, 0.9, a));
		}
	}
	else if (i < FLASH_0) {
		// ------------------------------------------------ SPARKS (stretched along velocity)
		int s = i - SPARK_0;
		float life = mix(0.4, 1.1, rnd(s, 0));
		float a = t / life;
		if (a < 1.0) {
			float a0 = -1.5708 + (rnd(s, 1) - 0.5) * TAU * 0.9;
			vec2 v0 = vec2(cos(a0), sin(a0)) * mix(250.0, 750.0, rnd(s, 2));
			float k = 1.8;
			pos = ballistic(t, v0, k, 500.0);
			vec2 vel = v0 * exp(-k * t) + vec2(0.0, 500.0) * t;
			ang = atan(vel.y, vel.x);
			float stretch = 1.0 + length(vel) * 0.012;
			sc = vec2(0.14 * stretch, 0.14);
			col = vec4(mix(vec3(1.0, 0.9, 0.5), vec3(1.0, 0.35, 0.05), a), 1.0 - a * a);
			glow = 1.0;
		}
	}
	else {
		// ------------------------------------------------ FLASH
		int f = i - FLASH_0;
		float life = 0.15 + 0.1 * float(f);
		float a = t / life;
		if (a < 1.0) {
			sc = vec2((3.5 + 1.5 * float(f)) * (0.6 + 0.8 * a));
			col = vec4(1.0, mix(0.95, 0.7, a), mix(0.8, 0.3, a), pow(1.0 - a, 2.0));
			glow = 1.0;
		}
	}

	TRANSFORM = xf(pos, ang, sc);
	COLOR = col;
	CUSTOM.w = glow;
}