shader_type canvas_item;

// 0.0 = totalmente cinza, 1.0 = cores originais.
// Cada região do mundo usa um material próprio, então cada uma
// pode recuperar a cor no seu próprio ritmo.
uniform float saturation : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
    COLOR.rgb = mix(vec3(gray), COLOR.rgb, saturation);
}
