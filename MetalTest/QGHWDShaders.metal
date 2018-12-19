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
    float2 textureMaskCoordinate;
} RasterizerData;

float3 RGBColorFromYuvTextures(sampler textureSampler, float2 coordinate, texture2d<float> texture_luma, texture2d<float> texture_chroma, matrix_float3x3 rotationMatrix, float2 offset) {
    
    float3 color;
    color.x = texture_luma.sample(textureSampler, coordinate).r;
    color.yz = texture_chroma.sample(textureSampler, coordinate).rg - offset;
    return float3(rotationMatrix * color);
}

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
    texture2d<float> texture_luma = textures[QGHWDYUVFragmentTextureIndexLuma];
    texture2d<float> texture_chroma = textures[QGHWDYUVFragmentTextureIndexChroma];
    matrix_float3x3 rotationMatrix = colorParameters[0].matrix;
    float2 offset = colorParameters[0].offset;
    
    float3 color = RGBColorFromYuvTextures(textureSampler, input.textureColorCoordinate, texture_luma, texture_chroma, rotationMatrix, offset);
    float3 alpha = RGBColorFromYuvTextures(textureSampler, input.textureAlphaCoordinate, texture_luma, texture_chroma, rotationMatrix, offset);
    return float4(color ,alpha.r);
}


