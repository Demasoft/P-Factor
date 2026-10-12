shader_type canvas_item;
// Draws one frame of a sprite sheet for every MultiMesh instance.
// base_frame is driven by the swarm's AnimationPlayer.
// INSTANCE_CUSTOM.r is a per-particle frame offset (desynchronises the animation).

uniform int h_frames = 1;
uniform int v_frames = 1;
uniform int base_frame = 0;

varying flat int frame_index;

void vertex() {
	int total_frames = h_frames * v_frames;
	frame_index = (base_frame + int(INSTANCE_CUSTOM.r + 0.5)) % total_frames;
}

void fragment() {
	int column = frame_index % h_frames;
	int row = frame_index / h_frames;
	vec2 frame_origin = vec2(float(column), float(row));
	vec2 frame_uv = (frame_origin + UV) / vec2(float(h_frames), float(v_frames));
	COLOR = texture(TEXTURE, frame_uv);
}
