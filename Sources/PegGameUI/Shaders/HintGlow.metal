#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Adds a pulsing colored halo around an opaque layer.
// Applied via SwiftUI `.layerEffect` with maxSampleOffset matching the
// expected glow radius (≈12pt).

[[ stitchable ]]
half4 hintGlow(float2 position, SwiftUI::Layer layer, float time, half4 glowColor) {
    half4 base = layer.sample(position);

    float pulse = 0.5 + 0.5 * sin(time * 2.6);
    float radius = 7.0 + 4.5 * pulse;

    constexpr int samples = 14;
    half haloAlpha = 0.0;
    for (int i = 0; i < samples; ++i) {
        float a = (float(i) / float(samples)) * 6.2831853;
        float2 offset = float2(cos(a), sin(a)) * radius;
        haloAlpha += layer.sample(position + offset).a;
    }
    haloAlpha /= float(samples);

    // Outside the original opaque area, render the glow at glowColor's hue.
    half outerHaloMask = haloAlpha * (1.0h - base.a);
    half3 halo = glowColor.rgb * outerHaloMask * half(0.7 + 0.3 * pulse);
    half outAlpha = max(base.a, outerHaloMask * glowColor.a * half(0.6 + 0.4 * pulse));

    return half4(base.rgb + halo, outAlpha);
}
