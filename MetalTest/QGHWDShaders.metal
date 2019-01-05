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

half3 RGBColorFromYuvTextures(sampler textureSampler, float2 coordinate, texture2d<float> texture_luma, texture2d<float> texture_chroma, half3x3 rotationMatrix, half2 offset) {
    
    half3 color;
    color.x = texture_luma.sample(textureSampler, coordinate).r;
    color.yz = half2(texture_chroma.sample(textureSampler, coordinate).rg) - offset;
    return half3(rotationMatrix * color); 
}

vertex HWDRasterizerData hwd_vertexShader(uint vertexID [[ vertex_id ]], constant QGHWDVertex *vertexArray [[ buffer(0) ]]) {
    
    HWDRasterizerData out;
    out.clipSpacePostion = vertexArray[vertexID].position;
    out.textureColorCoordinate = vertexArray[vertexID].textureColorCoordinate;
    out.textureAlphaCoordinate = vertexArray[vertexID].textureAlphaCoordinate; 
    return out;
}

fragment half4 hwd_yuvFragmentShader(HWDRasterizerData input [[ stage_in ]],
                                      texture2d<float>  lumaTexture [[ texture(0) ]],
                                      texture2d<float>  chromaTexture [[ texture(1) ]],
                                      constant ColorParameters *colorParameters [[ buffer(0) ]]) {
    //signifies that an expression may be computed at compile-time rather than runtime
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half3x3 rotationMatrix = half3x3(colorParameters[0].matrix);
    half2 offset = half2(colorParameters[0].offset);
    half3 color = RGBColorFromYuvTextures(textureSampler, input.textureColorCoordinate, lumaTexture, chromaTexture, rotationMatrix, offset);
    half3 alpha = RGBColorFromYuvTextures(textureSampler, input.textureAlphaCoordinate, lumaTexture, chromaTexture, rotationMatrix, offset);
    return half4(color ,alpha.r); 
}
