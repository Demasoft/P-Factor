shader_type canvas_item;

uniform sampler2D inside_texture : source_color;

uniform vec2 image_offset_pixels = vec2(0.0);
uniform vec2 image_scale = vec2(1.0);

void fragment() {
	// Text/glyph alpha
	vec4 glyph = texture(TEXTURE, UV);

	// One continuous image across the screen
	vec2 image_uv = SCREEN_UV;

	// Move image
	image_uv -= image_offset_pixels * SCREEN_PIXEL_SIZE;

	// Scale image around its center
	image_uv -= vec2(0.5);
	image_uv /= image_scale;
	image_uv += vec2(0.5);

	// Sample image
	vec4 image = texture(inside_texture, image_uv);

	// Use text as alpha mask
	COLOR.rgb = image.rgb;
	COLOR.a = glyph.a * image.a;
}