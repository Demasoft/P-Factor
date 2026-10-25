shader_type canvas_item;

uniform sampler2D noise_tex : hint_default_white, filter_linear, repeat_enable;
uniform vec4 root_color : source_color = vec4( 1.0, 0.75, 0.3, 1.0 );
uniform vec4 tip_color : source_color = vec4( 1.0, 0.03, 0.001, 1.0 );

uniform float fire_alpha : hint_range( 0.0, 1.0 ) = 1.0;
uniform vec2 fire_speed = vec2( 0.0, 1.0 );
uniform float fire_aperture : hint_range( 0.0, 3.0 ) = 0.22;
uniform vec2 noise_scale = vec2( 1.0, 1.0 );

// On: the node's texture (brightness) shapes the fire.
// Off: falls back to the original bottom-to-top falloff.
uniform bool use_texture_as_shape = true;
// On: also cut the fire out by the texture's alpha (useful for sprites).
uniform bool use_texture_alpha = true;

void fragment( )
{
	vec4 tex = texture( TEXTURE, UV );
	float height = use_texture_as_shape ? tex.r : UV.y;

	vec2 shifted_uv = UV * noise_scale + TIME * fire_speed;
	float fire_noise = texture( noise_tex, shifted_uv ).r;

	float noise = height * ( ( ( height + fire_aperture ) * fire_noise - fire_aperture ) * 75.0 );
	vec4 fire_color = mix( tip_color, root_color, noise * 0.05 );

	float alpha = clamp( noise, 0.0, 1.0 ) * fire_alpha;
	if ( use_texture_alpha ) {
		alpha *= tex.a;
	}

	COLOR = vec4( fire_color.rgb, alpha );
}