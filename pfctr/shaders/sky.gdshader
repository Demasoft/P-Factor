shader_type canvas_item;

// ---------------------------------------------------------------------------
// Parâmetros ajustáveis
// ---------------------------------------------------------------------------
uniform float cloudscale = 1.1;
uniform float speed = 0.01;
uniform float clouddark = 0.5;
uniform float cloudlight = 0.3;
uniform float cloudcover = 0.2;
uniform float cloudalpha = 8.0;
uniform float skytint = 0.5;

uniform vec3 skycolour1 = vec3(0.015, 0.025, 0.08); // topo do céu
uniform vec3 skycolour2 = vec3(0.05, 0.10, 0.25);   // base do céu
uniform vec3 cloud_base_colour = vec3(1.1, 1.1, 0.9);

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------
const mat2 OCTAVE_ROTATION = mat2(
	vec2(1.6, 1.2),
	vec2(-1.2, 1.6)
);

// Constantes do simplex noise 2D
const float SKEW_FACTOR = 0.366025404;
const float UNSKEW_FACTOR = 0.211324865;
const float NOISE_NORMALIZATION = 70.0;

// Velocidades relativas de cada camada de nuvem
const float SHAPE_TIME_FACTOR = 0.1;
const float DETAIL_TIME_FACTOR = 0.2;
const float WISP_TIME_FACTOR = 0.3;

// Escalas relativas de cada camada
const float WARP_SCALE_FACTOR = 0.5;
const float DETAIL_SCALE_FACTOR = 2.0;
const float WISP_SCALE_FACTOR = 3.0;

// ---------------------------------------------------------------------------
// Ruído
// ---------------------------------------------------------------------------
vec2 hash(vec2 p)
{
	p = vec2(
		dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3))
	);
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float simplex_noise(vec2 p)
{
	vec2 cell = floor(p + (p.x + p.y) * SKEW_FACTOR);

	// Vértices do triângulo simplex
	vec2 a = p - cell + (cell.x + cell.y) * UNSKEW_FACTOR;
	vec2 offset = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - offset + UNSKEW_FACTOR;
	vec2 c = a - 1.0 + 2.0 * UNSKEW_FACTOR;

	// Atenuação radial de cada vértice
	vec3 falloff = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 falloff4 = falloff * falloff * falloff * falloff;

	vec3 contributions = falloff4 * vec3(
		dot(a, hash(cell)),
		dot(b, hash(cell + offset)),
		dot(c, hash(cell + 1.0))
	);

	return dot(contributions, vec3(NOISE_NORMALIZATION));
}

/**
 * Soma várias oitavas de ruído, cada uma rotacionada e com peso menor.
 * Se `use_absolute` for true, usa |ruído|, o que gera bordas mais definidas.
 */
float fractal_noise(vec2 uv, float initial_weight, float weight_decay, int octaves, bool use_absolute)
{
	float total = 0.0;
	float weight = initial_weight;

	for (int i = 0; i < octaves; i++)
	{
		float n = simplex_noise(uv);
		total += weight * (use_absolute ? abs(n) : n);
		uv = OCTAVE_ROTATION * uv;
		weight *= weight_decay;
	}

	return total;
}

// ---------------------------------------------------------------------------
// Camadas de nuvem
// ---------------------------------------------------------------------------

/** Coordenada escalada, deformada pelo `warp` e deslocada pelo tempo. */
vec2 scrolling_uv(vec2 uv, float scale_factor, float warp, float time_factor, float time)
{
	vec2 scroll = vec2(time * speed * time_factor, 0.0);
	return uv * cloudscale * scale_factor + warp + scroll;
}

vec3 sky_colour(float vertical_position)
{
	return mix(skycolour1, skycolour2, vertical_position);
}

vec3 cloud_colour(float detail)
{
	float brightness = clamp(clouddark + cloudlight * detail, 0.0, 1.0);
	return cloud_base_colour * brightness;
}

// ---------------------------------------------------------------------------
// Fragment
// ---------------------------------------------------------------------------
void fragment()
{
	// Deformação base que "entorta" todas as camadas
	float warp = fractal_noise(UV * cloudscale * WARP_SCALE_FACTOR, 0.1, 0.4, 7, false);

	// Forma principal das nuvens (duas amostragens sobre as mesmas coordenadas)
	vec2 shape_uv = scrolling_uv(UV, 1.0, warp, SHAPE_TIME_FACTOR, TIME);
	float shape_edges = fractal_noise(shape_uv, 0.8, 0.7, 8, true);
	float shape_body = fractal_noise(shape_uv, 0.7, 0.6, 8, false);
	shape_body *= shape_edges + shape_body;

	// Detalhes de iluminação
	vec2 detail_uv = scrolling_uv(UV, DETAIL_SCALE_FACTOR, warp, DETAIL_TIME_FACTOR, TIME);
	vec2 wisp_uv = scrolling_uv(UV, WISP_SCALE_FACTOR, warp, WISP_TIME_FACTOR, TIME);
	float detail = fractal_noise(detail_uv, 0.4, 0.6, 7, false)
	             + fractal_noise(wisp_uv, 0.4, 0.6, 7, true);

	// Densidade final das nuvens
	float density = cloudcover + cloudalpha * shape_body * shape_edges;
	float cloud_mask = clamp(density + detail, 0.0, 1.0);

	// Composição
	vec3 sky = sky_colour(UV.y);
	vec3 cloud = clamp(skytint * sky + cloud_colour(detail), 0.0, 1.0);

	COLOR.rgb = mix(sky, cloud, cloud_mask);
}