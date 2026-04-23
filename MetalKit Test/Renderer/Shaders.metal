#include <metal_stdlib>
using namespace metal;

// Shared per-frame data (view, projection, lighting)
struct FrameUniforms {
    float4x4 view;
    float4x4 projection;
    float4   lightDir;  // w unused; avoids float3 struct-padding mismatch with Swift
};

// Per-object data for solid geometry
struct ObjectUniforms {
    float4x4 model;
    float4x4 normalMatrix;
    float4   color;
};

// Per-object data for line geometry
struct LineUniforms {
    float4x4 model;
    float4   color;
};

// ── Solid geometry (lit boxes) ──────────────────────────────────────────────

struct SolidVertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
};

struct SolidVertexOut {
    float4 position [[position]];
    float3 normal;
    float4 color;
};

vertex SolidVertexOut vertex_solid(SolidVertexIn in          [[stage_in]],
                                   constant FrameUniforms &frame [[buffer(1)]],
                                   constant ObjectUniforms &obj   [[buffer(2)]]) {
    float4 worldPos = obj.model * float4(in.position, 1.0);
    SolidVertexOut out;
    out.position = frame.projection * frame.view * worldPos;
    out.normal   = normalize((obj.normalMatrix * float4(in.normal, 0.0)).xyz);
    out.color    = obj.color;
    return out;
}

fragment float4 fragment_solid(SolidVertexOut in             [[stage_in]],
                                constant FrameUniforms &frame [[buffer(1)]]) {
    float3 L    = normalize(frame.lightDir.xyz);
    float  diff = max(dot(in.normal, L), 0.0);
    float  light = 0.25 + diff * 0.75;
    return float4(in.color.rgb * light, in.color.a);
}

// ── Line geometry (unlit grid and bounding box) ─────────────────────────────

struct LineVertexIn {
    float3 position [[attribute(0)]];
};

struct LineVertexOut {
    float4 position [[position]];
    float4 color;
};

vertex LineVertexOut vertex_line(LineVertexIn in              [[stage_in]],
                                  constant FrameUniforms &frame [[buffer(1)]],
                                  constant LineUniforms  &line  [[buffer(2)]]) {
    float4 worldPos = line.model * float4(in.position, 1.0);
    LineVertexOut out;
    out.position = frame.projection * frame.view * worldPos;
    out.color    = line.color;
    return out;
}

fragment float4 fragment_line(LineVertexOut in [[stage_in]]) {
    return in.color;
}
