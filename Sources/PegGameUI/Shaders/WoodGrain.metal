#include <metal_stdlib>
using namespace metal;

// Procedural wood-grain shader for the triangular game board.
// Bound via SwiftUI `.colorEffect`: position, incoming-color, size, time.

namespace peg_wood {

inline float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

inline float vnoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

inline float fbm(float2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; ++i) {
        v += a * vnoise(p);
        p = p * 2.03 + float2(11.7, 19.1);
        a *= 0.5;
    }
    return v;
}

} // namespace peg_wood

[[ stitchable ]]
half4 woodGrain(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / max(size, float2(1.0));

    // Place the "knot" offscreen so rings spread across the board in long arcs.
    float2 origin = float2(-0.35, 0.6);
    float2 d = uv - origin;
    // Stretch so rings elongate horizontally like real wood.
    float r = length(d * float2(0.45, 1.0));
    float distortion = peg_wood::fbm(uv * 6.0 + float2(time * 0.015, time * 0.008)) * 0.18;
    float ring = sin(r * 58.0 + distortion * 22.0);
    ring = smoothstep(-0.35, 0.45, ring);

    half3 dark  = half3(0.30, 0.16, 0.07);
    half3 mid   = half3(0.55, 0.32, 0.16);
    half3 light = half3(0.78, 0.55, 0.30);

    half3 base = mix(dark, mid, half(ring));

    // Fine vertical fiber streaks.
    float fiber = peg_wood::fbm(uv * float2(48.0, 4.0));
    base = mix(base, light, half(fiber * 0.22));

    // Varnish highlight near the top.
    float highlight = pow(max(0.0, 1.0 - uv.y), 3.0) * 0.18;
    base += half3(highlight);

    // Subtle vignette at edges.
    float2 vd = uv - 0.5;
    float vignette = 1.0 - smoothstep(0.45, 0.85, length(vd));
    base *= half(0.85 + 0.15 * vignette);

    return half4(base, color.a);
}
