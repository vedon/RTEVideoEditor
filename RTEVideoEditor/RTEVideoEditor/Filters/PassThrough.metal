//
//  PassTh.metal
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <simd/simd.h>
#import "RTEShaderTypes.h"

using namespace RTEMetal;

vertex VertexIO vertexPassThrough(uint          vid [[ vertex_id ]],
                                  const device  RTEVertex   * in       [[ buffer(RTEBufferIndexVertices) ]],
                                  constant      RTEUniforms & uniforms [[ buffer(RTEBufferIndexUniforms) ]])
{
    VertexIO outVertex;
    outVertex.position = uniforms.mvp * in[vid].position;
    outVertex.textureCoord = in[vid].texCoord;
    return outVertex;
}

fragment half4 fragmentPassThrough(VertexIO         inputFragment [[ stage_in ]],
                                   texture2d<half> inputTexture  [[ texture(0) ]],
                                   sampler         samplr        [[ sampler(0) ]])
{
    return inputTexture.sample(samplr, inputFragment.textureCoord);
}
