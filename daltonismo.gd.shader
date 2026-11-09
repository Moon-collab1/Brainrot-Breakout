shader_type canvas_item;
// Modo de filtro: 
// 0 = Normal
// 1 = Protanopía (ceguera al rojo)
// 2 = Deuteranopía (ceguera al verde)
// 3 = Tritanopía (ceguera al azul)
uniform int mode : hint_range(0, 3) = 0;
void fragment() {
    vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    if (mode == 1) {
        // Matriz aproximada para Protanopía
        mat3 transform = mat3(
            vec3(0.56667, 0.43333, 0.0),
            vec3(0.55833, 0.44167, 0.0),
            vec3(0.0,     0.24167, 0.75833)
        );
        c.rgb = transform * c.rgb;
    } else if (mode == 2) {
        // Matriz aproximada para Deuteranopía
        mat3 transform = mat3(
            vec3(0.625, 0.375, 0.0),
            vec3(0.7,   0.3,   0.0),
            vec3(0.0,   0.3,   0.7)
        );
        c.rgb = transform * c.rgb;
    } else if (mode == 3) {
        // Matriz aproximada para Tritanopía
        mat3 transform = mat3(
            vec3(0.95, 0.05,  0.0),
            vec3(0.0,  0.43333, 0.56667),
            vec3(0.0,  0.475,   0.525)
        );
        c.rgb = transform * c.rgb;
    }
    
    COLOR = c;
}