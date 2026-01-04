shader_type canvas_item;

uniform vec4 color1 = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color2 = vec4(1.0, 1.0, 1.0, 1.0);
uniform float threshold = 0.1;
uniform float intensity = 3.0;
uniform float opacity = 1.0;
uniform vec4 glow_color = vec4(1.0, 0.0, 0.0, 1.0); // bright red
uniform float time = 0.0;  // for pulsing
uniform float pulse_speed = 5.0;

void fragment() {
    vec4 pixel_color = texture(TEXTURE, UV);

    // distance from source colors
    float distance1 = length(pixel_color - color1);
    float distance2 = length(pixel_color - color2);

    // pulsating multiplier
    float pulse = 0.5 + 0.5 * sin(time * pulse_speed);

    vec4 modified_glow_color = glow_color;
    modified_glow_color.a = opacity;

    if (distance1 < threshold || distance2 < threshold) {
        COLOR = mix(pixel_color, modified_glow_color * intensity * pulse, modified_glow_color.a);
    } else {
        COLOR = pixel_color;
    }
}
