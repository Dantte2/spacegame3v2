shader_type canvas_item;

uniform float time;
uniform float rise_speed = 0.2;      // how fast smoke rises
uniform float swirl_strength = 0.05; // how much turbulence
uniform sampler2D noise_tex;         // a simple noise texture

void fragment() {
    vec2 uv = UV;

    // Add vertical rise over time
    uv.y -= time * rise_speed;

    // Sample noise for turbulence
    vec4 noise = texture(noise_tex, uv * 2.0 + time);
    uv.x += (noise.r - 0.5) * swirl_strength;

    // Sample original texture
    vec4 col = texture(TEXTURE, uv);

    // Fade out over time
    col.a *= 1.0 - time; // simple linear fade

    COLOR = col;
}
