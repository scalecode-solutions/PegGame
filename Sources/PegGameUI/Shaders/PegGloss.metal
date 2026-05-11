#include <metal_stdlib>
using namespace metal;

// Shades a circular peg as a glossy dome (faux-3D Lambert + specular).
// Applied via SwiftUI `.colorEffect` to a Circle filled with the peg's tint.
// Pixels outside the inscribed circle become transparent so the underlying
// hole shadow shows through.

[[ stitchable ]]
half4 pegGloss(float2 position, half4 color, float2 size) {
    float2 center = size * 0.5;
    float radius = min(size.x, size.y) * 0.5;
    float2 d = (position - center) / radius;
    float r2 = dot(d, d);
    if (r2 > 1.0) {
        return half4(0.0);
    }
    float z = sqrt(max(0.0, 1.0 - r2));
    float3 normal = normalize(float3(d.x, d.y, z));

    float3 lightDir = normalize(float3(-0.35, -0.55, 0.75));
    float lambert = max(dot(normal, lightDir), 0.0);
    float spec = pow(lambert, 28.0);

    // Soft rim highlight where the dome curls away from the camera.
    float rim = pow(1.0 - z, 2.0) * 0.35;

    half3 base = color.rgb;
    half3 lit = base * half(0.32 + 0.62 * lambert) + half3(spec * 0.75) + base * half(rim * 0.2);

    // Slight darkening at the very edge to fake a peg socket shadow.
    float edge = smoothstep(0.92, 1.0, sqrt(r2));
    lit *= half(1.0 - edge * 0.35);

    half alpha = color.a * half(1.0 - smoothstep(0.985, 1.0, sqrt(r2)));
    return half4(lit, alpha);
}
