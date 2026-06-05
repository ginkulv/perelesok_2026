shader_type canvas_item;

// Маска того же aspect ratio, что и спрайт. UV 0..1 — внутри картинки (без атласа).
uniform sampler2D mask_texture : filter_linear, repeat_disable;

void fragment() {
	vec4 dust_color = texture(TEXTURE, UV);
	float erased = texture(mask_texture, UV).r;
	dust_color.a *= (1.0 - erased);
	COLOR = dust_color;
}
