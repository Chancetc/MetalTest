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
    
    vector_float4 position;
    vector_float2 textureCoordinate;
} QGHWDVertex;

#endif /* QGHWDShaderTypes_h */
