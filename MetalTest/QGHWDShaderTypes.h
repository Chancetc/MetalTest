//
//  QGHWDShaderTypes.h
//  MetalTest
//
//  Created by Chance_xmu on 2018/12/13.
//  Copyright © 2018 Tencent. All rights reserved.
//

#ifndef QGHWDShaderTypes_h
#define QGHWDShaderTypes_h

#import <simd/simd.h>

typedef struct {
    
    packed_float4 position;
    packed_float2 textureColorCoordinate;
    packed_float2 textureAlphaCoordinate;
} QGHWDVertex;

struct ColorParameters
{
    matrix_float3x3 yuvToRGB;
};

#endif /* QGHWDShaderTypes_h */
