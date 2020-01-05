//
//  RTEShaderTypes.h
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

#ifndef RTEShaderTypes_h
#define RTEShaderTypes_h
#include <simd/simd.h>

typedef struct
{
    vector_float4 position;
    packed_float2 texCoord;
} RTEVertex;

typedef enum RTEBufferIndex
{
    RTEBufferIndexVertices = 0,
    RTEBufferIndexUniforms = 1,
} RTEBufferIndex;

typedef enum RTETextureIndex
{
    RTETextureIndexBaseMap = 0,
    RTETextureIndexLabelMap = 1
} RTETextureIndex;

typedef struct
{
    matrix_float4x4 mvp;
} RTEUniforms;

#endif /* RTEShaderTypes_h */
