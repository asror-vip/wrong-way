shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 15.0) = 2.8;
uniform vec4 tint_color : source_color = vec4(0.04, 0.05, 0.09, 0.28);

void fragment() {
	if (blur_amount <= 0.01) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
		
		// 17-Tap Circular Bokeh Sampling
		// Center
		vec4 col = texture(TEXTURE, UV) * 0.16;
		
		// Ring 1 (Radius 1.0, 6 taps at 60 deg intervals)
		col += texture(TEXTURE, UV + vec2(ps.x * 1.000, 0.000)) * 0.07;
		col += texture(TEXTURE, UV + vec2(ps.x * 0.500, ps.y * 0.866)) * 0.07;
		col += texture(TEXTURE, UV + vec2(-ps.x * 0.500, ps.y * 0.866)) * 0.07;
		col += texture(TEXTURE, UV + vec2(-ps.x * 1.000, 0.000)) * 0.07;
		col += texture(TEXTURE, UV + vec2(-ps.x * 0.500, -ps.y * 0.866)) * 0.07;
		col += texture(TEXTURE, UV + vec2(ps.x * 0.500, -ps.y * 0.866)) * 0.07;
		
		// Ring 2 (Radius 2.0, 8 taps at 45 deg intervals)
		col += texture(TEXTURE, UV + vec2(ps.x * 2.000, 0.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(ps.x * 1.414, ps.y * 1.414)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(0.000, ps.y * 2.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(-ps.x * 1.414, ps.y * 1.414)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(-ps.x * 2.000, 0.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(-ps.x * 1.414, -ps.y * 1.414)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(0.000, -ps.y * 2.000)) * 0.0525;
		col += texture(TEXTURE, UV + vec2(ps.x * 1.414, -ps.y * 1.414)) * 0.0525;
		
		// Soft atmospheric tint to sink into the deep background
		col.rgb = mix(col.rgb, tint_color.rgb, tint_color.a);
		COLOR = col;
	}
}
