shader_type canvas_item;

// Wrong Way - High-Fantasy Biome Transition Mist Shader
// Multi-layered domain-warped volumetric mist with luminous atmospheric scattering

uniform vec4 fog_color_left : source_color = vec4(0.70, 0.80, 0.92, 0.80);
uniform vec4 fog_color_right : source_color = vec4(0.90, 0.95, 1.00, 0.85);
uniform vec4 glow_color : source_color = vec4(0.55, 0.82, 1.00, 0.50);
uniform float density : hint_range(0.0, 2.5) = 1.1;
uniform float speed : hint_range(0.0, 0.5) = 0.06;
uniform float edge_fade_exp : hint_range(0.2, 2.0) = 0.65;
uniform float vertical_spread : hint_range(0.5, 2.0) = 1.0;

// High-speed pseudo-random 2D hash
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 2D Value Noise with quintic Hermite interpolation
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Quintic smooth curve for silky smooth clouds
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	
	float a = dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0));
	float b = dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	float c = dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	float d = dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
	
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 4-Octave Fractal Brownian Motion
float fbm4(vec2 p) {
	float val = 0.0;
	float amp = 0.50;
	float freq = 1.0;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	
	for (int i = 0; i < 4; i++) {
		val += amp * value_noise(p * freq);
		p = rot * p * 2.02 + vec2(1.6, 2.4);
		amp *= 0.48;
	}
	return val;
}

// Domain-Warped Cloud Function: creates billowing, swirling fog tendrils
float domain_warped_fog(vec2 p, float t) {
	vec2 q = vec2(
		fbm4(p + vec2(t * 0.25, t * 0.10)),
		fbm4(p + vec2(t * -0.18, t * 0.22) + vec2(5.2, 1.3))
	);
	
	vec2 r = vec2(
		fbm4(p + 1.8 * q + vec2(1.7, 9.2) + vec2(t * 0.15, -t * 0.12)),
		fbm4(p + 1.8 * q + vec2(8.3, 2.8) + vec2(-t * 0.10, t * 0.20))
	);
	
	return fbm4(p + 2.0 * r);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	
	// Coordinate space: stretch slightly for horizontal billowing
	vec2 p = vec2(uv.x * 2.8, uv.y * 3.8 * vertical_spread);
	
	// Primary drifting fog layer
	float fog1 = domain_warped_fog(p + vec2(t * 0.35, t * 0.08), t);
	
	// Secondary counter-drifting layer for volumetric depth
	float fog2 = domain_warped_fog(p * 1.35 - vec2(t * 0.20, -t * 0.15) + vec2(12.4, 7.1), t * 0.8);
	
	// Composite organic cloud density (0.0 .. 1.0)
	float density_raw = 0.50 + 0.38 * fog1 + 0.26 * fog2;
	float cloud = smoothstep(0.20, 0.82, density_raw);
	
	// Wide horizontal fade so mist melts into the world edges
	float edge_fade = sin(clamp(uv.x, 0.0, 1.0) * 3.14159265);
	edge_fade = pow(edge_fade, edge_fade_exp);
	
	// Soft vertical gradient (natural mountain gorge atmosphere)
	float vert_fade = 0.80 + 0.20 * sin(uv.y * 3.14159265);
	
	// Color interpolation from left biome to right biome
	vec4 base_col = mix(fog_color_left, fog_color_right, uv.x);
	
	// Luminous light scattering: bright silver-blue or emerald highlights
	float rim = pow(clamp(fog1 * 0.5 + 0.5, 0.0, 1.0), 3.0);
	vec3 illuminated_rgb = mix(base_col.rgb, glow_color.rgb, rim * glow_color.a);
	
	// Central atmospheric bloom
	float core_glow = pow(edge_fade, 2.2) * cloud;
	illuminated_rgb += glow_color.rgb * core_glow * 0.25;
	
	float final_alpha = cloud * edge_fade * vert_fade * density * base_col.a;
	COLOR = vec4(illuminated_rgb, clamp(final_alpha, 0.0, 1.0));
}
