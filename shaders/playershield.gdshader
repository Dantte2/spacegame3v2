shader_type canvas_item;

// -----------------------------
// Shield parameters
// -----------------------------
uniform float shield_length = 0.3;
uniform float shield_radius = 0.25;

// -----------------------------
// Hit parameters
// -----------------------------
uniform vec2 hit_uv = vec2(0.5, 0.5);
uniform float hit_strength = 1.0;
uniform float hit_glow_radius = 0.1;
uniform vec4 hit_color = vec4(5.0, 8.0, 10.0, 1.0);

// -----------------------------
// Break / fragment parameters
// -----------------------------
uniform float break_strength = 0.0;   // 0 = intact, 1 = fully broken
uniform vec4 fragment_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform float time = 0.0;

// -----------------------------
// Random function
// -----------------------------
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
    vec2 uv_corr = uv * vec2(aspect, 1.0);

    // -----------------------------
    // Capsule geometry
    // -----------------------------
    vec2 left_center   = vec2(-shield_length * 0.5, 0.0);
    vec2 right_center  = vec2( shield_length * 0.5, 0.0);
    vec2 center_center = vec2(0.0, 0.0);

    float d_left   = length(uv_corr - left_center)   - shield_radius;
    float d_right  = length(uv_corr - right_center)  - shield_radius;
    float d_center = length(uv_corr - center_center) - shield_radius;

    float dist = min(d_left, min(d_right, d_center));

    float shield_mask = smoothstep(0.01, 0.0, dist);
    
    vec4 final_color = vec4(0.0);

    if (shield_mask > 0.01) {
        // -----------------------------
        // Hit glow
        // -----------------------------
        vec2 hit_local = hit_uv - vec2(0.5);
        hit_local.x *= aspect;
        float hit_dist = length(uv_corr - hit_local);
        float hit_glow = exp(-pow(hit_dist / hit_glow_radius, 2.0)) * hit_strength;
        hit_glow *= shield_mask;

        // -----------------------------
        // Imploding fragments
        // -----------------------------
        float edge = smoothstep(0.0, 0.01, abs(dist));

        float n = hash(floor(uv_corr * 50.0));

        // Direction towards center (implode)
        vec2 frag_dir = -normalize(uv_corr); // negative to move inward
        frag_dir *= 0.2 + 0.3 * n; // random speed

        // Small rotation for chaos
        float angle = n * 6.2831;
        frag_dir = vec2(
            frag_dir.x * cos(angle) - frag_dir.y * sin(angle),
            frag_dir.x * sin(angle) + frag_dir.y * cos(angle)
        );

        vec2 frag_offset = frag_dir * break_strength;

        // Fade as it collapses
        float frag_fade = clamp(1.0 - break_strength * (0.5 + n * 0.5), 0.0, 1.0);

        float show_fragment = step(1.0 - break_strength, n) * frag_fade;
        float fragment_glow = edge * show_fragment;

        // -----------------------------
        // Combine hit + fragments
        // -----------------------------
        final_color = hit_color * hit_glow + fragment_color * fragment_glow;
        final_color *= shield_mask;
    }

    COLOR = final_color;
}
