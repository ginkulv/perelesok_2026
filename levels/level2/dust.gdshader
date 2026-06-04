shader_type canvas_item;

// Brush mask texture (white = erased, black = dust remains)
uniform sampler2D mask_texture;

void fragment() {
    // Get the dust color
    vec4 dust_color = texture(TEXTURE, UV);
    
    // Get the mask value at this pixel
    float mask = texture(mask_texture, UV).r;
    
    // Where mask is white (1.0), make dust transparent
    dust_color.a = dust_color.a * (1.0 - mask);
    
    COLOR = dust_color;

}
