shader_type canvas_item;

uniform vec4 player_color  : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 bandana_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float src_hue_center  : hint_range(0.0, 1.0) = 0.595;
uniform float src_hue_range   : hint_range(0.0, 0.5) = 0.20;
uniform float src_val         : hint_range(0.0, 1.0) = 0.708;
uniform float band_hue_center : hint_range(0.0, 1.0) = 0.998;
uniform float band_hue_range  : hint_range(0.0, 0.5) = 0.05;
uniform float sat_min         : hint_range(0.0, 1.0) = 0.12;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 0.00000001;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    vec3 hsv_px = rgb2hsv(col.rgb);

    float body_diff = abs(hsv_px.x - src_hue_center);
    body_diff = min(body_diff, 1.0 - body_diff);

    float band_diff = abs(hsv_px.x - band_hue_center);
    band_diff = min(band_diff, 1.0 - band_diff);

    if (col.a > 0.01 && hsv_px.y > sat_min && body_diff < src_hue_range) {
        vec3 hsv_tgt = rgb2hsv(player_color.rgb);
        float new_sat = hsv_px.y * clamp(hsv_tgt.y * 2.0, 0.0, 1.0);
        float new_val = clamp(hsv_px.z * (hsv_tgt.z / src_val), 0.0, 1.0);
        COLOR = vec4(hsv2rgb(vec3(hsv_tgt.x, new_sat, new_val)), col.a);

    } else if (col.a > 0.01 && hsv_px.y > sat_min && band_diff < band_hue_range) {
        vec3 hsv_band = rgb2hsv(bandana_color.rgb);
        float new_sat = hsv_px.y * clamp(hsv_band.y * 2.0, 0.0, 1.0);
        // 0.81 = V lineal del tono claro original del panuelo (#E7333B)
        // Escala proporcional: preserva la diferencia entre tono claro y oscuro
        float new_val = hsv_px.z * (hsv_band.z / 0.81);
        COLOR = vec4(hsv2rgb(vec3(hsv_band.x, new_sat, clamp(new_val, 0.0, 1.0))), col.a);

    } else {
        COLOR = col;
    }
}
