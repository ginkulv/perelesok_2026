shader_type canvas_item;

uniform sampler2D clean_texture;  // чистая текстура
uniform sampler2D dirty_texture;  // грязная текстура
uniform vec2 mouse_pos;           // позиция курсора
uniform float radius = 50.0;      // радиус протирки

void fragment() {
    vec4 dirty = texture(dirty_texture, UV);
    vec4 clean = texture(clean_texture, UV);
    
    // Расстояние от текущего пикселя до курсора
    float dist = distance(UV, mouse_pos);
    
    // Смешиваем чистую и грязную текстуру
    float mix_factor = 0.0;
    if (dist < radius) {
        mix_factor = 1.0 - (dist / radius);
    }
    
    COLOR = mix(dirty, clean, mix_factor);
}