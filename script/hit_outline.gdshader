shader_type canvas_item;

instance uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float outline_width : hint_range(0.0, 10.0) = 0.0;
instance uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	// Flash effect: mix original color with white based on hit_strength
	vec3 flash_col = mix(col.rgb, vec3(1.0, 1.0, 1.0), hit_strength);
	
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	
	float alpha = col.a;
	alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	
	if (col.a < 0.1 && alpha > 0.1) {
		COLOR = outline_color * COLOR;
	} else {
		COLOR = vec4(flash_col, col.a) * COLOR;
	}
}
