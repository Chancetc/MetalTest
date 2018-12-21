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

vertex HWDAttachmentRasterizerData hwdAttachment_vertexShader(uint vertexID [[ vertex_id ]], constant QGHWDAttachmentVertex *vertexArray [[ buffer(0) ]]) {
    
    HWDAttachmentRasterizerData out;
    out.position = vertexArray[vertexID].position;
    out.sourceTextureCoordinate = vertexArray[vertexID].sourceTextureCoordinate;
    out.maskTextureCoordinate =  vertexArray[vertexID].maskTextureCoordinate;
    return out;
}

fragment float4 hwdAttachment_fragmentShader(HWDAttachmentRasterizerData input [[ stage_in ]],
                                             texture2d<float>  sourceTexture [[ texture(0) ]],
                                             texture2d<float>  maskTexture [[ texture(1) ]],
                                             constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = sourceTexture.sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = maskTexture.sample(textureSampler, input.maskTextureCoordinate);
    return source+mask;
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
                                                    texture2d<float>  sourceTexture [[ texture(0) ]],
                                                    texture2d<float>  maskTexture [[ texture(1) ]],
                                                    constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = sourceTexture.sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = maskTexture.sample(textureSampler, input.maskTextureCoordinate);
    float alpha = params[0].alpha;
    return float4(source.rgb,source.a*alpha*(1-mask.a));
}

fragment float4 hwdAttachment_fragmentShader_srcMix(HWDAttachmentRasterizerData input [[ stage_in ]],
                                                    texture2d<float>  sourceTexture [[ texture(0) ]],
                                                    texture2d<float>  maskTexture [[ texture(1) ]],
                                                    constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = sourceTexture.sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = maskTexture.sample(textureSampler, input.maskTextureCoordinate);
    float2 blend = float2(1.0-mask.a, mask.a);
    float4 color = source*blend.x+mask*blend.y;
    float alpha = params[0].alpha;
    return float4(color.rgb, step(0.01, mask.a)*alpha);
}
