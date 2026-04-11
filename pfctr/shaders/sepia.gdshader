shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture,repeat_disable,filter_nearest;

void fragment() {
    vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
    vec3 burn = vec3(172.0,113.0,37.0) / 255.0;

    COLOR.rgb = screen + burn * 0.2;
}


