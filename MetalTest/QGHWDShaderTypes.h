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

struct ColorParameters {
    
    matrix_float3x3 matrix;
    packed_float2 offset;
};

// Argument buffer indices shared between shader and C code to ensure Metal shader buffer
//   input match Metal API texture set calls
typedef enum QGHWDArgumentBufferID {
    
    QGHWDArgumentBufferIDTextures  = 0,
    QGHWDArgumentBufferIDBuffers   = 100,
    QGHWDArgumentBufferIDConstants = 200
} AQGHWDArgumentBufferID;

typedef enum QGHWDYUVFragmentTextureIndex {
    
    QGHWDYUVFragmentTextureIndexLuma            = 0,
    QGHWDYUVFragmentTextureIndexChroma          = 1,
    QGHWDYUVFragmentTextureIndexAttachmentStart = 2,
} QGHWDYUVFragmentTextureIndex;

// Constant values shared between shader and C code which indicate the size of argument arrays
//   in the structure defining the argument buffers
typedef enum QGHWDNumArguments {
    
    QGHWDNumBufferArguments  = 20,
    QGHWDNumTextureArguments = 20
} QGHWDNumArguments;

#endif /* QGHWDShaderTypes_h */
