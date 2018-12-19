//
//  QGHWDAttachmentShader.metal
//  MetalTest
//
//  Created by Chanceguo on 2018/12/19.
//  Copyright © 2018 Tencent. All rights reserved.
//

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
                                      array<texture2d<float>, 2> textures [[ texture(0) ]],
                                      constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = textures[0].sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = textures[1].sample(textureSampler, input.maskTextureCoordinate);
    return source+mask;
}

fragment float4 hwdAttachment_fragmentShader_srcIn(HWDAttachmentRasterizerData input [[ stage_in ]],
                                             array<texture2d<float>, 2> textures [[ texture(0) ]],
                                             constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = textures[0].sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = textures[1].sample(textureSampler, input.maskTextureCoordinate);
    float alpha = params[0].alpha;
    if (mask.a < 0.1) {
        return float4(0.0);
    } else {
        return float4(source.rgb,source.a*alpha);
    }
}

fragment float4 hwdAttachment_fragmentShader_srcOut(HWDAttachmentRasterizerData input [[ stage_in ]],
                                                   array<texture2d<float>, 2> textures [[ texture(0) ]],
                                                   constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 source = textures[0].sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = textures[1].sample(textureSampler, input.maskTextureCoordinate);
    float alpha = params[0].alpha;
    if (mask.a < 0.1) {
        return float4(source.rgb,source.a*alpha);
    } else {
        return float4(0.0);
    }
}

fragment float4 hwdAttachment_fragmentShader_srcMix(HWDAttachmentRasterizerData input [[ stage_in ]],
                                                   array<texture2d<float>, 2> textures [[ texture(0) ]],
                                                   constant QGHWDAttachmentFragmentParameter *params [[ buffer(0) ]]) {
    
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
//    float alpha = params[0].alpha;
    float4 source = textures[0].sample(textureSampler, input.sourceTextureCoordinate);
    float4 mask = textures[1].sample(textureSampler, input.maskTextureCoordinate);
    float2 blend = float2(1.0-mask.a, mask.a);
    if (mask.a < 0.1) {
        return float4(0.0);
    }
    return float4(source.r*blend.x+mask.r*blend.y, source.g*blend.x+mask.g*blend.y, source.b*blend.x+mask.b*blend.y,1.0);
}
