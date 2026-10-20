/*
	Explosion particle process shader (GPUParticles2D)
	Pairs with explosion_draw.gdshader
*/
shader_type particles;

uniform vec2 blast_direction = vec2( 0.0, -1.0 );		// direction the debris sprays (Vector2.UP by default)
uniform float spread_deg : hint_range( 0.0, 360.0 ) = 50.0;
uniform float emission_radius = 6.0;					// px, spawn disc around the node

group_uniforms kinds;
uniform float debris_ratio : hint_range( 0.0, 1.0 ) = 0.3;
uniform float fire_ratio : hint_range( 0.0, 1.0 ) = 0.3;	// the rest is smoke

group_uniforms debris;
uniform vec2 debris_speed = vec2( 250.0, 700.0 );		// px/s, min and max
uniform vec2 debris_size = vec2( 0.08, 0.2 );			// multiplies the texture size
uniform float debris_stretch = 0.003;					// extra length per px/s of speed
uniform vec2 debris_gravity = vec2( 0.0, 900.0 );
uniform float debris_drag = 1.2;

group_uniforms fireball;
uniform vec2 fireball_speed = vec2( 20.0, 160.0 );
uniform float fireball_lean : hint_range( 0.0, 2.0 ) = 0.5;	// how much the blast leans toward blast_direction
uniform vec2 fireball_size = vec2( 0.8, 1.6 );
uniform float fireball_drag = 3.0;

group_uniforms smoke;
uniform vec2 smoke_speed = vec2( 10.0, 90.0 );
uniform vec2 smoke_size = vec2( 1.0, 1.8 );
uniform float smoke_growth : hint_range( 1.0, 4.0 ) = 2.0;
uniform vec2 smoke_rise = vec2( 0.0, -60.0 );			// buoyancy, px/s^2
uniform float smoke_drag = 1.5;
uniform float smoke_delay : hint_range( 0.0, 1.0 ) = 0.2;	// share of its life smoke waits, so it follows the fire

// CUSTOM: x = random 0..1, y = phase (0..1 over life, negative = waiting), z = kind, w = life scale

float rand_from_seed( inout uint seed )
{
	int k;
	int s = int( seed );
	if ( s == 0 ) {
		s = 305420679;
	}
	k = s / 127773;
	s = 16807 * ( s - k * 127773 ) - 2836 * k;
	if ( s < 0 ) {
		s += 2147483647;
	}
	seed = uint( s );
	return float( seed % uint( 65536 ) ) / 65535.0;
}

vec2 rotate2( vec2 v, float a )
{
	float c = cos( a );
	float s = sin( a );
	return vec2( c * v.x - s * v.y, s * v.x + c * v.y );
}

void start( )
{
	uint seed = RANDOM_SEED;
	float r_size = rand_from_seed( seed );
	float r_ang = rand_from_seed( seed );
	float r_speed = rand_from_seed( seed );
	float r_life = rand_from_seed( seed );
	float r_pos_a = rand_from_seed( seed );
	float r_pos_r = rand_from_seed( seed );

	vec2 dir = length( blast_direction ) > 0.0001 ? normalize( blast_direction ) : vec2( 0.0, -1.0 );

	// Smoke first, then fire, then debris, so with Draw Order = Index debris is drawn on top
	float smoke_part = 1.0 - debris_ratio - fire_ratio;
	float kind = AMOUNT_RATIO < smoke_part ? 1.0 : ( AMOUNT_RATIO < smoke_part + fire_ratio ? 0.0 : 2.0 );

	TRANSFORM = EMISSION_TRANSFORM;
	TRANSFORM[3].xy += rotate2( vec2( 1.0, 0.0 ), r_pos_a * 6.28318 ) * sqrt( r_pos_r ) * emission_radius;

	vec2 vel;
	float life_scale;
	float phase0 = 0.0;

	if ( kind < 0.5 ) {
		// Fire: bursts outward, leaning toward the blast direction, dies first
		vec2 radial = rotate2( vec2( 1.0, 0.0 ), r_ang * 6.28318 );
		vel = ( radial + dir * fireball_lean ) * mix( fireball_speed.x, fireball_speed.y, r_speed );
		life_scale = mix( 0.45, 0.65, r_life );
	} else if ( kind < 1.5 ) {
		// Smoke: slower, waits a little, lives the longest
		vec2 radial = rotate2( vec2( 1.0, 0.0 ), r_ang * 6.28318 );
		vel = ( radial + dir * fireball_lean ) * mix( smoke_speed.x, smoke_speed.y, r_speed );
		life_scale = mix( 0.8, 1.0, r_life ) / ( 1.0 + smoke_delay );
		phase0 = -smoke_delay;
	} else {
		// Debris: fast, inside a cone around blast_direction
		float a = ( r_ang - 0.5 ) * radians( spread_deg );
		vel = rotate2( dir, a ) * mix( debris_speed.x, debris_speed.y, r_speed );
		life_scale = mix( 0.6, 0.95, r_life );
	}

	VELOCITY = vec3( vel, 0.0 );
	CUSTOM = vec4( r_size, phase0, kind, life_scale );
	COLOR = vec4( 1.0 );
}

void process( )
{
	CUSTOM.y += DELTA / ( LIFETIME * CUSTOM.w );
	float ph = CUSTOM.y;
	if ( ph >= 1.0 ) {
		ACTIVE = false;
		return;
	}

	float p = clamp( ph, 0.0, 1.0 );
	float kind = CUSTOM.z;
	float r = CUSTOM.x;

	vec2 vel = VELOCITY.xy;
	vec2 accel = vec2( 0.0 );
	float drag;
	vec2 scl;
	float ang = 0.0;

	if ( kind < 0.5 ) {
		drag = fireball_drag;
		float s = mix( fireball_size.x, fireball_size.y, r );
		float grow = 1.0 - pow( 1.0 - min( p / 0.3, 1.0 ), 2.0 );
		s *= mix( 0.4, 1.0, grow ) * mix( 1.0, 0.6, smoothstep( 0.3, 1.0, p ) );
		scl = vec2( s );
	} else if ( kind < 1.5 ) {
		drag = smoke_drag;
		accel = smoke_rise;
		float s = mix( smoke_size.x, smoke_size.y, r );
		s *= mix( 1.0, smoke_growth, 1.0 - pow( 1.0 - p, 2.0 ) );
		scl = vec2( s );
	} else {
		drag = debris_drag;
		accel = debris_gravity;
		float s = mix( debris_size.x, debris_size.y, r ) * mix( 1.0, 0.4, p );
		scl = vec2( s * ( 1.0 + length( vel ) * debris_stretch ), s );
		ang = atan( vel.y, vel.x );
	}

	vel += accel * DELTA;
	vel *= exp( -drag * DELTA );
	VELOCITY.xy = vel;
	TRANSFORM[3].xy += vel * DELTA;

	vec2 ax = vec2( cos( ang ), sin( ang ) );
	TRANSFORM[0] = vec4( ax * scl.x, 0.0, 0.0 );
	TRANSFORM[1] = vec4( vec2( -ax.y, ax.x ) * scl.y, 0.0, 0.0 );
	TRANSFORM[2] = vec4( 0.0, 0.0, 1.0, 0.0 );
}