shader_type canvas_item;
render_mode unshaded;
uniform vec2 points[5];
uniform vec4 banks[3];
uniform vec4 islands[2];
uniform float half_width = 23.0;
uniform bool lit = false;
uniform vec2 beam = vec2(0.0);
uniform float support_radius = 56.0;
uniform vec2 charge_centers[32];
uniform float charge_strength[32];
uniform int charge_count = 0;
uniform float memory_radius = 36.0;
uniform vec4 route_color : source_color = vec4(0.65,0.83,0.79,1.0);
uniform sampler2D terrain : source_color, filter_linear;
varying vec2 world_point;
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
bool in_rect(vec2 p, vec4 rect) { return all(greaterThanEqual(p,rect.xy)) && all(lessThan(p,rect.xy+rect.zw)); }
void fragment() {
    vec2 p = world_point;
    // Banks and the inset tops of safety islands are drawn as permanent solids.
    bool bank = in_rect(p,banks[0]) || in_rect(p,banks[1]) || in_rect(p,banks[2]);
    bool island = in_rect(p,islands[0]) || in_rect(p,islands[1]);
    float d = 9999.0;
    float along = 0.0;
    float traveled = 0.0;
    for (int i=0; i<4; i++) {
        vec2 edge = points[i+1]-points[i];
        float t = clamp(dot(p-points[i],edge)/dot(edge,edge),0.0,1.0);
        float candidate = length(p-points[i]-edge*t);
        if (candidate < d) { d = candidate; along = traveled+length(edge)*t; }
        traveled += length(edge);
    }
    if (d > half_width || bank || island) { discard; }
    bool supported = lit && distance(p,beam) <= support_radius;
    float stored = 0.0;
    if (lit) {
        for (int i=0; i<32; i++) {
            if (i >= charge_count) { break; }
            if (distance(p,charge_centers[i]) <= memory_radius) { stored = max(stored,charge_strength[i]); }
        }
    }
    supported = supported || stored > 0.0;
    float rim = smoothstep(half_width-1.7,half_width,d);
    if (supported) {
        vec3 stone = texture(terrain,vec2(0.5,0.0)+fract(p/210.0)*0.5).rgb;
        float joint = step(mod(along,24.0),1.3);
        vec3 color = mix(stone*vec3(1.22,1.15,0.92),vec3(0.33,0.34,0.26),joint*0.5);
        COLOR = vec4(mix(color,vec3(1.0,0.88,0.55),rim*(0.35+0.35*stored)),1.0);
    } else {
        // Only a dashed outline in darkness, never a misleading solid bridge.
        float dash = step(3.0,mod(along,16.0));
        COLOR = vec4(route_color.rgb, rim*0.35*dash);
    }
}
