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

kernel void
hwd_yuvToRGB(texture2d<float, access::read> lumaTexture[[texture(0)]],
         texture2d<float, access::read> chromaTexture[[texture(1)]],
         texture2d<float, access::write> outTexture[[texture(2)]],
         constant ColorParameters *colorParameters [[ buffer(0) ]],
         uint2 gid [[thread_position_in_grid]]) {
    
    float3 yuv;
    yuv.x = lumaTexture.read(gid).r;
    yuv.yz = chromaTexture.read(gid/2).rg - colorParameters[0].offset;
    float3 rgb = colorParameters[0].matrix * yuv;
    outTexture.write(float4(rgb, yuv.x), gid); 
}

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
                                      texture2d<float>  texture [[ texture(0) ]]) {
    //signifies that an expression may be computed at compile-time rather than runtime
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    return float4(texture.sample(textureSampler, input.textureColorCoordinate).rgb, texture.sample(textureSampler, input.textureAlphaCoordinate).r); 
}


