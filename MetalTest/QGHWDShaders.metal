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
                                      array<texture2d<float>, QGHWDNumTextureArguments> textures [[ texture(0) ]],
                                      constant ColorParameters *colorParameters [[ buffer(0) ]],
                                      constant int &validTextureCount [[ buffer(1) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float3 color,alpha;
    float2 offset = colorParameters[0].offset;
    texture2d<float> texture_luma = textures[QGHWDYUVFragmentTextureIndexLuma];
    uint32_t chromaIndex = validTextureCount-9;
    //?没理解这里
    if (chromaIndex != 1) {
        return float4(1.0,0.0,0.0,0.0);
    }
    texture2d<float> texture_chroma = textures[validTextureCount-9];//QGHWDYUVFragmentTextureIndexChroma
    color.x = texture_luma.sample(textureSampler, input.textureColorCoordinate).r;
    color.yz = texture_chroma.sample(textureSampler,input.textureColorCoordinate).rg - offset;
    alpha.x = texture_luma.sample(textureSampler, input.textureAlphaCoordinate).r;
    alpha.yz = texture_chroma.sample(textureSampler,input.textureAlphaCoordinate).rg - offset;
    
    matrix_float3x3 rotationMatrix = colorParameters[0].matrix;
    return float4(float3(rotationMatrix * color),float3(rotationMatrix * alpha).r);
}
