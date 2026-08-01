#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

float hash(float2 p) {
  return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

[[ stitchable ]]
half4 grainGradient(float2 position, float4 bounds, float strength) {
  float2 uv = position / bounds.zw;
  float gradient = smoothstep(0.0, 1.2, uv.y + 0.2);
  float2 p = fmod(position, float2(1024.0));
  float noise = hash(p);
  float alpha = noise * strength * (0.5 + gradient * 0.5);
  return half4(0.05, 0.05, 0.05, clamp(alpha, 0.0, 1.0));
}
