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
} HWDRasterizerData;

float3 RGBColorFromYuvTextures(sampler textureSampler, float2 coordinate, texture2d<float> texture_luma, texture2d<float> texture_chroma, matrix_float3x3 rotationMatrix, float2 offset) {
    
    float3 color;
    color.x = texture_luma.sample(textureSampler, coordinate).r;
    color.yz = texture_chroma.sample(textureSampler, coordinate).rg - offset;
    return float3(rotationMatrix * color);
}

vertex HWDRasterizerData hwd_vertexShader(uint vertexID [[ vertex_id ]], constant QGHWDVertex *vertexArray [[ buffer(0) ]]) {
    
    HWDRasterizerData out;
    out.clipSpacePostion = vertexArray[vertexID].position;
    out.textureColorCoordinate = vertexArray[vertexID].textureColorCoordinate;
    out.textureAlphaCoordinate = vertexArray[vertexID].textureAlphaCoordinate;
    return out;
}

fragment float4 hwd_yuvFragmentShader(HWDRasterizerData input [[ stage_in ]],
                                      texture2d<float>  lumaTexture [[ texture(0) ]],
                                      texture2d<float>  chromaTexture [[ texture(1) ]],
                                      constant ColorParameters *colorParameters [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    matrix_float3x3 rotationMatrix = colorParameters[0].matrix;
    float2 offset = colorParameters[0].offset;
    float3 color = RGBColorFromYuvTextures(textureSampler, input.textureColorCoordinate, lumaTexture, chromaTexture, rotationMatrix, offset);
    float3 alpha = RGBColorFromYuvTextures(textureSampler, input.textureAlphaCoordinate, lumaTexture, chromaTexture, rotationMatrix, offset);
    return float4(color ,alpha.r);
}


