//
//  Shaders.metal
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/12.
//  Copyright © 2018 Tencent. All rights reserved.
//

#include <metal_stdlib>
#import "QGHWDShaderTypes.h"

using namespace metal;

typedef struct {
    
    float4 clipSpacePostion [[ position ]];
    float2 textureColorCoordinate;
    float2 textureAlphaCoordinate;
} RasterizerData;

vertex RasterizerData hwd_vertexShader(uint vertexID [[ vertex_id ]], constant QGHWDVertex *vertexArray [[ buffer(0) ]]) {
    
    RasterizerData out;
    out.clipSpacePostion = vertexArray[vertexID].position;
    out.textureColorCoordinate = vertexArray[vertexID].textureColorCoordinate;
    out.textureAlphaCoordinate = vertexArray[vertexID].textureAlphaCoordinate;
    return out;
}

fragment float4 hwd_fragmentShader(RasterizerData input [[ stage_in ]], texture2d<float> texture [[ texture(0)]]) {
    
    constexpr sampler colorSampler (mag_filter::linear, min_filter::linear);
    constexpr sampler alphaSampler (mag_filter::linear, min_filter::linear);
    float4 colorSample = texture.sample(colorSampler, input.textureColorCoordinate);
    float4 alphaSample = texture.sample(alphaSampler, input.textureAlphaCoordinate);
    return float4(colorSample.rgb,alphaSample.r);
}
