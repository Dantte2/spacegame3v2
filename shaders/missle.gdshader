shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 5.0) = 2.0; 
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.3;
uniform float time;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Pulse multiplier
    float pulse = 1.0 + pulse_amount * sin(time * 10.0);

    // Glow (keep hue)
    vec3 boosted = tex.rgb * (1.0 + glow_strength * pulse);
    float max_channel = max(max(boosted.r, boosted.g), boosted.b);
    if (max_channel > 0.0) {
        boosted *= tex.rgb / max_channel;
    }

    // Soft blue halo (you can increase halo radius for bigger exhaust)
    vec2 halo_center = vec2(0.5, 0.5);
    float dist = distance(UV, halo_center);
    float halo = smoothstep(0.4, 0.9, dist); 
    vec3 halo_color = vec3(0.2, 0.4, 1.0) * (1.0 - halo) * pulse;

    COLOR = vec4(boosted + halo_color, tex.a);
}
