// все права принадлежат ООО DeepSeek
// vhs_with_noise.gdshader
shader_type canvas_item;

// VHS parameters
uniform float vhs_strength : hint_range(0.0, 1.0) = 0.5;
uniform float jitter_amount : hint_range(0.0, 0.1) = 0.02;
uniform float color_bleed : hint_range(0.0, 0.1) = 0.015;
uniform float scanline_intensity : hint_range(0.0, 0.5) = 0.25;

// Noise parameters
uniform float noise_strength : hint_range(0.0, 0.5) = 0.08;
uniform float noise_speed : hint_range(0.0, 5.0) = 1.0;

// Master control
uniform float master_strength : hint_range(0.0, 1.0) = 1.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    float t = TIME;
    
    // ===== VHS EFFECTS =====
    // Vertical jitter
    float jitter = random(vec2(floor(uv.y * 200.0), t * 2.0)) * jitter_amount * vhs_strength;
    uv.y += jitter;
    
    // Horizontal shake
    float shake = sin(t * 30.0) * 0.015 * vhs_strength;
    uv.x += shake;
    
    // Color bleeding
    vec4 color_r = texture(TEXTURE, uv + vec2(color_bleed * vhs_strength, 0.0));
    vec4 color_g = texture(TEXTURE, uv);
    vec4 color_b = texture(TEXTURE, uv - vec2(color_bleed * vhs_strength, 0.0));
    vec4 color = vec4(color_r.r, color_g.g, color_b.b, color_g.a);
    
    // Scanlines
    float scanline = sin(uv.y * 800.0 + t * 20.0) * scanline_intensity * vhs_strength;
    color.rgb -= scanline;
    
    // ===== NOISE EFFECT =====
    float noise = random(uv + t * noise_speed) * noise_strength;
    color.rgb += vec3(noise);
    
    // Apply master strength
    vec4 original = texture(TEXTURE, UV);
    COLOR = mix(original, color, master_strength);
}
