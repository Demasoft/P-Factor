shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

uniform float blur_strength = 3.0;
uniform float radius = 0.35;
uniform float softness = 0.45;
uniform float darkness = 0.5; // 0 = no darkening, 1 = full black edges

void fragment() {
    vec2 uv = SCREEN_UV;

    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);

    float vignette = smoothstep(radius, radius + softness, dist);

    float blur = vignette * blur_strength;

    vec4 col = vec4(0.0);
    col += texture(screen_texture, uv + vec2(-blur, -blur) * SCREEN_PIXEL_SIZE);
    col += texture(screen_texture, uv + vec2(-blur, blur) * SCREEN_PIXEL_SIZE);
    col += texture(screen_texture, uv + vec2(blur, -blur) * SCREEN_PIXEL_SIZE);
    col += texture(screen_texture, uv + vec2(blur, blur) * SCREEN_PIXEL_SIZE);
    col += texture(screen_texture, uv);

    col /= 5.0;

    // Darken edges
    col.rgb *= mix(1.0, 1.0 - darkness, vignette);

    COLOR = col;
}