//
//  QGHWDAttachmentShader.metal
//  MetalTest
//
//  Created by Chanceguo on 2018/12/19.
//  Copyright © 2018 Tencent. All rights reserved.
//
//specification:https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf

#include <metal_stdlib>
#import "QGHWDShaderTypes.h"

using namespace metal;

typedef struct {
    
    float4 position [[ position ]];
    float2 sourceTextureCoordinate;
    float2 maskTextureCoordinate;
} HWDAttachmentRasterizerData;

float3 RGBColorFromYuv(sampler textureSampler, float2 coordinate, texture2d<float> texture_luma, texture2d<float> texture_chroma, matrix_float3x3 rotationMatrix, float2 offset) {
    
    float3 color;
    color.x = texture_luma.sample(textureSampler, coordinate).r;
    color.yz = texture_chroma.sample(textureSampler, coordinate).rg - offset;
    return float3(rotationMatrix * color);
}

vertex HWDAttachmentRasterizerData hwdAttachment_vertexShader(uint vertexID [[ vertex_id ]], constant QGHWDAttachmentVertex *vertexArray [[ buffer(0) ]]) {
    
    HWDAttachmentRasterizerData out;
    out.position = vertexArray[vertexID].position;
    out.sourceTextureCoordinate = vertexArray[vertexID].sourceTextureCoordinate;
    out.maskTextureCoordinate =  vertexArray[vertexID].maskTextureCoordinate;
    return out;
}

fragment float4 hwdAttachment_fragmentShader_srcIn(HWDAttachmentRasterizerData input [[ stage_in ]],
                                                   texture2d<float>  sourceTexture [[ texture(0) ]],
                                                   texture2d<float>  maskTexture [[ texture(1) ]],
                                                   constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = sourceTexture.sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = maskTexture.sample(textureSampler, input.maskTextureCoordinate);
    float alpha = params[0].alpha;
    return float4(source.rgb,source.a*alpha*(1-mask.a));
}

fragment float4 hwdAttachment_fragmentShader_srcOut(HWDAttachmentRasterizerData input [[ stage_in ]],
                                                   texture2d<float>  desLumaTexture [[ texture(0) ]],
                                                   texture2d<float>  desChromaTexture [[ texture(1) ]],
                                                   texture2d<float>  sourceTexture [[ texture(2) ]],
                                                   constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float2 offset = params[0].offset;
    matrix_float3x3 rotationMatrix = params[0].matrix;
    
    float3 mask = RGBColorFromYuv(textureSampler, input.maskTextureCoordinate, desLumaTexture, desChromaTexture, rotationMatrix, offset);
    float4 source = sourceTexture.sample(textureSampler, input.sourceTextureCoordinate);
    float alpha = params[0].alpha;
    return float4(source.rgb,source.a*alpha*mask.r);
}

fragment float4 hwdAttachment_fragmentShader_srcMix(HWDAttachmentRasterizerData input [[ stage_in ]],
                                                    texture2d<float>  sourceTexture [[ texture(0) ]],
                                                    texture2d<float>  maskTexture [[ texture(1) ]],
                                                    constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = sourceTexture.sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = maskTexture.sample(textureSampler, input.maskTextureCoordinate);
    return float4(source.rgb, mask.a);
}
