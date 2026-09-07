shader_type canvas_item;
render_mode unshaded;
// The generated atlas is preserved untouched; chroma is removed at render time.
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    float key = min(c.r, c.b) - c.g;
    c.a *= 1.0 - smoothstep(0.18, 0.43, key);
    COLOR = c;
}
