//
//  PassTh.metal
//  RTEVideoEditor
//
//  Created by weidong fu on 2020/1/1.
//  Copyright © 2020 Free. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void rosyEffect(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
                       texture2d<half, access::write> outputTexture [[ texture(1) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }
    
    half4 inputColor = inputTexture.read(gid);
    
    half4 outputColor = half4(inputColor.r, 0.0, inputColor.b, 1.0);
    
    outputTexture.write(outputColor, gid);
}
