shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;
uniform float glow_width : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	// Create a rim glow effect based on distance from center
	float dist = distance(UV, vec2(0.5));
	float rim = smoothstep(0.5 - glow_width, 0.5, dist);
	
	// Apply glow to the edge of the sprite
	vec3 final_color = col.rgb + (glow_color.rgb * rim * glow_intensity * col.a);
	
	COLOR = vec4(final_color, col.a);
}
