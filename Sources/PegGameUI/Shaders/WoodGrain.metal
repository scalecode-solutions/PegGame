#include <metal_stdlib>
using namespace metal;

// Pine-plank shader for the triangular game board.
//
// Goals:
//   - Long horizontal grain lines running with the wood, not concentric rings.
//   - Subtle contrast — the wood is the *stage*, the pegs are the hero.
//   - Honey/cream pine palette, with the occasional darker amber streak that
//     reads as a growth ring.
//
// Bound via SwiftUI `.colorEffect` on a Rectangle that's then clipped to the
// triangle outline. Parameters: position, incoming-color, size.

namespace peg_pine {

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
    for (int i = 0; i < 4; ++i) {
        v += a * vnoise(p);
        p = p * 2.13 + float2(11.7, 19.1);
        a *= 0.5;
    }
    return v;
}

} // namespace peg_pine

[[ stitchable ]]
half4 woodGrain(float2 position, half4 color, float2 size) {
    float2 uv = position / max(size, float2(1.0));

    // Long parallel grain lines along the wood's length. The X axis is the
    // grain direction; perturb the Y position with low-frequency noise so the
    // lines wave gently instead of running ruler-straight.
    float perturbation = peg_pine::fbm(uv * float2(2.0, 14.0)) * 0.45;
    float grainBands = uv.y * 22.0 + perturbation;
    float grain = sin(grainBands * 3.14159) * 0.5 + 0.5;        // 0...1
    // Soften the grain so individual stripes don't punch out.
    grain = smoothstep(0.18, 0.82, grain);

    // Broad, slowly-varying brightness across the plank — simulates the camera
    // not being perfectly perpendicular to a chunk of natural wood.
    float undulation = peg_pine::fbm(uv * float2(2.6, 1.4));

    // Pine palette: pale cream → honey → darker amber for growth rings.
    half3 cream  = half3(0.94, 0.81, 0.59);
    half3 honey  = half3(0.82, 0.65, 0.40);
    half3 amber  = half3(0.66, 0.46, 0.24);

    // Base is mostly honey with a tilt toward cream in the lighter ranges.
    half3 base = mix(honey, cream, half(undulation * 0.55 + 0.15));

    // Layer in subtle grain darkening (the soft bands between fibers).
    base = mix(base, base * half3(0.86, 0.84, 0.80), half(grain * 0.28));

    // Occasional darker amber growth-ring streak: sharp valleys only.
    float ringStreak = smoothstep(0.78, 1.0, grain);
    base = mix(base, amber, half(ringStreak * 0.30));

    // Very fine micro-fiber speckle for surface texture.
    float speckle = peg_pine::fbm(uv * float2(60.0, 8.0));
    base *= half(0.96 + 0.06 * speckle);

    // Gentle top-down lighting: top edge slightly brighter than bottom.
    float lighting = 0.94 + 0.10 * (1.0 - uv.y);
    base *= half(lighting);

    return half4(base, color.a);
}
