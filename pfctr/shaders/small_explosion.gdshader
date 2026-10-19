/*
	Fire + Smoke puffs with noise erosion (canvas_item)
	Fire ramp based on Fire Shader by Yui Kinomoto @arlez80 (MIT License)
*/
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D noise_tex : hint_default_white, filter_linear, repeat_enable;
uniform vec4 root_color : source_color = vec4( 1.0, 0.75, 0.3, 1.0 );
uniform vec4 tip_color : source_color = vec4( 1.0, 0.03, 0.001, 1.0 );
uniform vec4 smoke_dark : source_color = vec4( 0.12, 0.12, 0.13, 1.0 );
uniform vec4 smoke_light : source_color = vec4( 0.45, 0.45, 0.47, 1.0 );

uniform int particle_count : hint_range( 1, 80 ) = 28;
uniform float lifetime : hint_range( 0.2, 10.0 ) = 3.0;
uniform float fire_portion : hint_range( 0.05, 0.95 ) = 0.35;

uniform vec2 emit_origin = vec2( 0.5, 0.9 );
uniform float emit_width : hint_range( 0.0, 1.0 ) = 0.25;
uniform float rise_height : hint_range( 0.0, 2.0 ) = 0.8;
uniform float wobble : hint_range( 0.0, 0.5 ) = 0.07;

// Bigger puffs than the plain particle version
uniform float size_min : hint_range( 0.01, 0.6 ) = 0.08;
uniform float size_max : hint_range( 0.01, 0.6 ) = 0.15;
uniform float smoke_growth : hint_range( 1.0, 4.0 ) = 1.8;

// Noise erosion (from the original shader)
uniform vec2 fire_speed = vec2( 0.0, 1.0 );
uniform float noise_scale : hint_range( 0.1, 4.0 ) = 1.0;
uniform float fire_aperture : hint_range( 0.0, 1.0 ) = 0.15;	// erosion while it is fire
uniform float smoke_aperture : hint_range( 0.0, 1.0 ) = 0.45;	// erosion at end of life

uniform float fire_alpha : hint_range( 0.0, 1.0 ) = 1.0;
uniform float smoke_alpha : hint_range( 0.0, 1.0 ) = 0.55;
uniform float aspect_ratio = 1.0;

float hash21( vec2 p )
{
	vec3 p3 = fract( vec3( p.xyx ) * 0.1031 );
	p3 += dot( p3, p3.yzx + 33.33 );
	return fract( ( p3.x + p3.y ) * p3.z );
}

void fragment( )
{
	vec3 acc_rgb = vec3( 0.0 );
	float acc_a = 0.0;
	float n = float( particle_count );

	for ( int i = 0; i < particle_count; i++ ) {
		float fi = float( i );
		float t = TIME / lifetime + fi / n;
		float cycle = floor( t );
		float life = fract( t );

		vec2 seed = vec2( fi, cycle );
		float r1 = hash21( seed );
		float r2 = hash21( seed + 17.31 );
		float r3 = hash21( seed + 41.77 );
		float r4 = hash21( seed + 73.19 );

		float x01 = fract( fi * 0.618034 + cycle * 0.381966 ) + ( r1 - 0.5 ) * 0.15;
		float start_x = emit_origin.x + ( x01 - 0.5 ) * emit_width;
		float speed = 0.7 + 0.6 * r2;
		vec2 pos = vec2(
			start_x + sin( life * 6.2831 * ( 0.5 + r3 ) + r1 * 6.2831 ) * wobble * life,
			emit_origin.y - life * rise_height * speed
		);

		float f = clamp( life / fire_portion, 0.0, 1.0 );
		float s = clamp( ( life - fire_portion ) / ( 1.0 - fire_portion ), 0.0, 1.0 );
		float radius = mix( size_min, size_max, r3 ) * mix( 1.0, 0.6, f ) * mix( 1.0, smoke_growth, s );

		vec2 local = ( UV - pos ) * vec2( aspect_ratio, 1.0 ) / radius;	// -1..1 across the puff
		float d = length( local );
		if ( d >= 1.0 ) {
			continue;
		}

		// The circle plays the role of the "height" texture
		float height = 1.0 - d;

		// Noise in the puff's own space: moves with it, differs per puff
		vec2 noise_uv = local * 0.5 * noise_scale + vec2( r1, r4 ) * 10.0 + TIME * fire_speed;
		float fire_noise = texture( noise_tex, noise_uv ).r;

		// More erosion as the puff ages, so it breaks up into wisps
		float aperture = mix( fire_aperture, smoke_aperture, smoothstep( 0.0, 1.0, life ) );
		float noise = height * ( ( ( height + aperture ) * fire_noise - aperture ) * 75.0 );
		float shape = clamp( noise, 0.0, 1.0 );
		if ( shape <= 0.0 ) {
			continue;
		}
		float heat = clamp( noise * 0.05, 0.0, 1.0 );

		float fire_w = 1.0 - smoothstep( fire_portion * 0.6, fire_portion, life );
		float smoke_w = smoothstep( fire_portion * 0.5, fire_portion * 1.2, life ) * ( 1.0 - s * s );

		// Smoke: lit from the dense core, darker at ragged edges
		float sa = shape * smoke_w * smoke_alpha;
		vec3 smoke_rgb = mix( smoke_dark.rgb, smoke_light.rgb, heat );
		acc_rgb = smoke_rgb * sa + acc_rgb * ( 1.0 - sa );
		acc_a = sa + acc_a * ( 1.0 - sa );

		// Fire: original root/tip ramp driven by the eroded noise value
		float fa = shape * fire_w * fire_alpha;
		vec3 fire_rgb = mix( tip_color.rgb, root_color.rgb, heat );
		acc_rgb += fire_rgb * fa;
		acc_a = clamp( acc_a + fa * ( 1.0 - acc_a ), 0.0, 1.0 );
	}

	COLOR = vec4( acc_rgb, acc_a );
}