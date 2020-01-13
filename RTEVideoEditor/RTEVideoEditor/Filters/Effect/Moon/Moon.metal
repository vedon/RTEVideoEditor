//
//  Moon.metal
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/7.
//  Copyright © 2020 Free. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <simd/simd.h>
#import "../../RTEShaderTypes.h"
using namespace RTEMetal;

fragment float4 moonEffect(VertexIO vertexIn [[ stage_in ]],
    texture2d<float, access::sample> inputTexture [[ texture(0) ]],
    texture2d<float, access::sample> map1 [[ texture(1) ]],
    texture2d<float, access::sample> map2 [[ texture(2) ]],
    sampler textureSampler [[ sampler(0) ]])
{
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float4 texel = inputTexture.sample(s, vertexIn.textureCoord);
    float4 inputTexel = texel;
    // apply curves
    texel.r = map1.sample(s, float2(texel.r, 0.5)).r;
    texel.g = map1.sample(s, float2(texel.g, 0.5)).g;
    texel.b = map1.sample(s, float2(texel.b, 0.5)).b;

    // saturation
    float3 desat = float3(dot(float3(0.7, 0.2, 0.1), texel.rgb));
    texel.rgb = mix(texel.rgb, desat, 0.79);

    // channel-weighted bw conversion and exposure boost
    texel.rgb = float3(min(1.0, 1.2 * dot(float3(0.2, 0.7, 0.1), texel.rgb)));

    // apply final curves and lgg
    texel.r = map2.sample(s, float2(texel.r, 0.5)).r;
    texel.g = map2.sample(s, float2(texel.g, 0.5)).g;
    texel.b = map2.sample(s, float2(texel.b, 0.5)).b;
    texel.rgb = mix(inputTexel.rgb, texel.rgb, 1.0);
    return texel;
}

