shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_radius : hint_range(0.0, 12.0) = 4.5;
uniform vec4 tint_color : source_color = vec4(0.04, 0.06, 0.11, 0.74);

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_radius;
	vec3 col = texture(screen_texture, SCREEN_UV).rgb * 0.24;
	col += texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)).rgb * 0.11;
	col += texture(screen_texture, SCREEN_UV - vec2(px.x, 0.0)).rgb * 0.11;
	col += texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)).rgb * 0.11;
	col += texture(screen_texture, SCREEN_UV - vec2(0.0, px.y)).rgb * 0.11;
	col += texture(screen_texture, SCREEN_UV + vec2(px.x, px.y)).rgb * 0.08;
	col += texture(screen_texture, SCREEN_UV + vec2(-px.x, px.y)).rgb * 0.08;
	col += texture(screen_texture, SCREEN_UV + vec2(px.x, -px.y)).rgb * 0.08;
	col += texture(screen_texture, SCREEN_UV + vec2(-px.x, -px.y)).rgb * 0.08;

	vec3 frosted = mix(col, tint_color.rgb, tint_color.a);
	COLOR = vec4(frosted, 1.0);
}
