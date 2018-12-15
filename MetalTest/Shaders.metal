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

fragment float4 hwd_yuvFragmentShader(RasterizerData input [[ stage_in ]],
                                      texture2d<float> lumaTex [[ texture(0) ]],
                                      texture2d<float> chromaTex [[ texture(1) ]],
                                      constant ColorParameters *colorParameters [[ buffer(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float3 color,alpha;
    color.x = lumaTex.sample(textureSampler, input.textureColorCoordinate).r;
    color.yz = chromaTex.sample(textureSampler,input.textureColorCoordinate).rg - float2(0.5);
    alpha.x = lumaTex.sample(textureSampler, input.textureAlphaCoordinate).r;
    alpha.yz = chromaTex.sample(textureSampler,input.textureAlphaCoordinate).rg - float2(0.5);
    
    matrix_float3x3 rotationMatrix = colorParameters[0].yuvToRGB;
    return float4(float3(rotationMatrix * color),float3(rotationMatrix * alpha).r);
}
