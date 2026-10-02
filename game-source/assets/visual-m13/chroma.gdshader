shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
uniform float hit_flash : hint_range(0.0,1.0) = 0.0;
void vertex() { vertex_tint = COLOR; }
// The generated atlas is preserved untouched; chroma is removed at render time.
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    float key = min(c.r, c.b) - c.g;
    c.a *= 1.0 - smoothstep(0.18, 0.43, key);
    c.rgb = mix(c.rgb,vec3(1.0,0.96,0.83),hit_flash);
    COLOR = c * vertex_tint;
}
