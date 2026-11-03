shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 15.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.04, 0.05, 0.09, 0.0);
uniform float fade_left : hint_range(0.0, 0.5) = 0.0;
uniform float fade_right : hint_range(0.0, 0.5) = 0.0;

void fragment() {
	vec4 col = vec4(0.0);
	if (blur_amount <= 0.01) {
		col = texture(TEXTURE, UV);
	} else {
		vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
		
		// 17-Tap Circular Bokeh Sampling
		col = texture(TEXTURE, UV) * 0.16;
		col += texture(TEXTURE, UV + vec2(ps.x * 1.000, 0.000)) * 0.07;
		col += texture(TEXTURE, UV + vec2(ps.x * 0.500, ps.y * 0.866)) * 0.07;
		col += texture(TEXTURE, UV + vec2(-ps.x * 0.500, ps.y * 0.866)) * 0.07;
		col += texture(TEXTURE, UV + vec2(-ps.x * 1.000, 0.000)) * 0.07;
		col += texture(TEXTURE, UV + vec2(-ps.x * 0.500, -ps.y * 0.866)) * 0.07;
		col += texture(TEXTURE, UV + vec2(ps.x * 0.500, -ps.y * 0.866)) * 0.07;
		
		col += texture(TEXTURE, UV + vec2(ps.x * 2.000, 0.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(ps.x * 1.414, ps.y * 1.414)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(0.000, ps.y * 2.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(-ps.x * 1.414, ps.y * 1.414)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(-ps.x * 2.000, 0.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(-ps.x * 1.414, -ps.y * 1.414)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(0.000, -ps.y * 2.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(ps.x * 1.414, -ps.y * 1.414)) * 0.0525;
		
		col.rgb = mix(col.rgb, tint_color.rgb, tint_color.a);
	}
	
	// Smooth organic boundary edge fade for biome transitions
	float alpha_mult = 1.0;
	if (fade_left > 0.001) {
		alpha_mult *= smoothstep(0.0, fade_left, UV.x);
	}
	if (fade_right > 0.001) {
		alpha_mult *= (1.0 - smoothstep(1.0 - fade_right, 1.0, UV.x));
	}
	col.a *= alpha_mult;
	COLOR = col;
}