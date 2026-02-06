shader_type canvas_item;

// La textura de cesped que vayas a usar
uniform sampler2D textura_cesped : repeat_enable; 
uniform vec2 escala_textura = vec2(1.0, 1.0);
uniform vec2 velocidad_scroll = vec2(0.0, 0.0);

void fragment() {
    // Multiplicamos la UV por la escala para que se "duplique" en lugar de estirarse
    // Sumamos el TIME para el movimiento infinito
    vec2 uv_repetida = (UV * escala_textura) + (TIME * velocidad_scroll);
    
    // Leemos la textura con la nueva UV
    vec4 color_textura = texture(textura_cesped, uv_repetida);
    
    COLOR = color_textura;
}