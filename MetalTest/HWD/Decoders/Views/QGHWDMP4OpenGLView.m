//
//  QGHWDMP4OpenGLView.m
//  QGame
//
//  Created by Chanceguo on 2017/3/2.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "QGHWDMP4OpenGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVUtilities.h>
#import <mach/mach_time.h>
#import <GLKit/GLKit.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

// Uniform index.
enum {
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD_RGB,
    ATTRIB_TEXCOORD_ALPHA,
    NUM_ATTRIBUTES
};

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
		  0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
const GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};


// texture coords for blend

const GLfloat textureCoordLeft[] =  { // 左侧
    0.5, 0.0,
    0.0, 0.0,
    0.5, 1.0,
    0.0, 1.0
};

const GLfloat textureCoordRight[] =  { // 右侧
    1.0, 0.0,
    0.5, 0.0,
    1.0, 1.0,
    0.5, 1.0
};

const GLfloat textureCoordTop[] =  { // 上侧
    1.0, 0.0,
    0.0, 0.0,
    1.0, 0.5,
    0.0, 0.5
};

const GLfloat textureCoordBottom[] =  { // 下侧
    1.0, 0.5,
    0.0, 0.5,
    1.0, 1.0,
    0.0, 1.0
};

#undef cos
#undef sin
NSString *const kVertexShaderSource = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 RGBTexCoord;
 attribute vec2 alphaTexCoord;
 
 varying vec2 RGBTexCoordVarying;
 varying vec2 alphaTexCoordVarying;
 
 void main()
{
    float preferredRotation = 3.14;
    mat4 rotationMatrix = mat4(cos(preferredRotation), -sin(preferredRotation), 0.0, 0.0,sin(preferredRotation),cos(preferredRotation), 0.0, 0.0,0.0,0.0,1.0,0.0,0.0,0.0, 0.0,1.0);
    gl_Position = rotationMatrix * position;
    RGBTexCoordVarying = RGBTexCoord;
    alphaTexCoordVarying = alphaTexCoord;
}
 );

NSString *const kFragmentShaderSource = SHADER_STRING
(
 varying highp vec2 RGBTexCoordVarying;
 varying highp vec2 alphaTexCoordVarying;
 precision mediump float;
 
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 uniform mat3 colorConversionMatrix;
 
 void main()
{
    mediump vec3 yuv_rgb;
    lowp vec3 rgb_rgb;
    
    mediump vec3 yuv_alpha;
    lowp vec3 rgb_alpha;
    
    // Subtract constants to map the video range start at 0
    yuv_rgb.x = (texture2D(SamplerY, RGBTexCoordVarying).r);// - (16.0/255.0));
    yuv_rgb.yz = (texture2D(SamplerUV, RGBTexCoordVarying).ra - vec2(0.5, 0.5));
    
    rgb_rgb = colorConversionMatrix * yuv_rgb;
    
    
    yuv_alpha.x = (texture2D(SamplerY, alphaTexCoordVarying).r);// - (16.0/255.0));
    yuv_alpha.yz = (texture2D(SamplerUV, alphaTexCoordVarying).ra - vec2(0.5, 0.5));
    
    rgb_alpha = colorConversionMatrix * yuv_alpha;
    
    
    gl_FragColor = vec4(rgb_rgb,rgb_alpha.r);
    //    gl_FragColor = vec4(1, 0, 0, 1);
}
 );


@interface QGHWDMP4OpenGLView() {

    // The pixel dimensions of the CAEAGLLayer.
    GLint _backingWidth;
    GLint _backingHeight;
    
    EAGLContext *_context;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    GLuint _frameBufferHandle;
    GLuint _colorBufferHandle;
    
    const GLfloat *_preferredConversion;
}

@property GLuint program;

- (void)setupBuffers;
- (void)cleanUpTextures;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation QGHWDMP4OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]))
    {
        if (![self commonInit]) {
            return  nil;
        }
    }
    return self;
}

- (instancetype)init {
    
    if (self = [super init]) {
        if (![self commonInit]) {
            return  nil;
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        if (![self commonInit]) {
            return  nil;
        }
    }
    return self;
}

- (BOOL)commonInit {
    
    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = NO;
    eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking :[NSNumber numberWithBool:NO],
                                      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context || ![EAGLContext setCurrentContext:_context] || ![self loadShaders]) {
        return NO;
    }
    
    _preferredConversion = kColorConversion709;
    return YES;
}

# pragma mark - OpenGL setup

- (void)setupGL {
    
    //QG_Info(MODULE_DECODE, @"setupGL");
    [EAGLContext setCurrentContext:_context];
    [self setupBuffers];
    [self loadShaders];
    
    glUseProgram(self.program);
    
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);
    
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    
    // Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (!_videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
        if (err != noErr) {
            //QG_Event(MODULE_DECODE,@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
}

#pragma mark - Utilities

- (void)setupBuffers {
    
    glDisable(GL_DEPTH_TEST);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD_RGB);
    glVertexAttribPointer(ATTRIB_TEXCOORD_RGB, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD_ALPHA);
    glVertexAttribPointer(ATTRIB_TEXCOORD_ALPHA, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        //QG_Event(MODULE_DECODE,@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)cleanUpTextures {
    
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc {
    
    //QG_Info(MODULE_DECODE, @"opengl view dealloc");
    [self cleanUpTextures];
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    if ([self.displayDelegate respondsToSelector:@selector(onViewUnavailableStatus)]) {
        [self.displayDelegate onViewUnavailableStatus];
        
    }
}

#pragma mark - OpenGLES drawing

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    if (!self.window && [self.displayDelegate respondsToSelector:@selector(onViewUnavailableStatus)]) {
        [self.displayDelegate onViewUnavailableStatus];
        return ;
    }
    
    CVReturn err;
    if (pixelBuffer != NULL) {
        int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!_videoTextureCache) {
            //QG_Event(MODULE_DECODE,@"No video texture cache");
            return;
        }
        if ([EAGLContext currentContext] != _context) {
            [EAGLContext setCurrentContext:_context];
        }
        [self cleanUpTextures];

        /*
         Use the color attachment of the pixel buffer to determine the appropriate color conversion matrix.
         */
//        CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
        _preferredConversion = kColorConversion601FullRange;
        
        /*
         CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture optimally from CVPixelBufferRef.
         */
        
        /*
         Create Y and UV textures from the pixel buffer. These textures will be drawn on the frame buffer Y-plane.
         */
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_LUMINANCE,
                                                           frameWidth,
                                                           frameHeight,
                                                           GL_LUMINANCE,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        if (err) {
            //QG_Event(MODULE_DECODE,@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_LUMINANCE_ALPHA,
                                                           frameWidth / 2.0,
                                                           frameHeight / 2.0,
                                                           GL_LUMINANCE_ALPHA,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err) {
            //QG_Event(MODULE_DECODE,@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        //        NSLog(@"id %d", CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
        
        // Set the view port to the entire view.
        glViewport(0, 0, _backingWidth, _backingHeight);
    }
    
//    glClearColor(0.1f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Use shader program.
    glUseProgram(self.program);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    
    // Set up the quad vertices with respect to the orientation and aspect ratio of the video.
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(_backingWidth, _backingHeight), self.layer.bounds);
    
    // Compute normalized quad coordinates to draw the frame into.
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/self.layer.bounds.size.width, vertexSamplingRect.size.height/self.layer.bounds.size.height);
    
    // Normalize the quad vertices.
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.width/cropScaleAmount.height;
    }
    
    /*
     The quad vertex data defines the region of 2D plane onto which we draw our pixel buffers.
     Vertex data formed using (-1,-1) and (1,1) as the bottom left and top right coordinates respectively, covers the entire screen.
     */
    GLfloat quadVertexData [] = {
        -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        -1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
        normalizedSamplingSize.width, normalizedSamplingSize.height,
    };
    
    // 更新顶点数据
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(ATTRIB_VERTEX);

    glVertexAttribPointer(ATTRIB_TEXCOORD_RGB, 2, GL_FLOAT, 0, 0, [self quadTextureRGBData]);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD_RGB);
    
    glVertexAttribPointer(ATTRIB_TEXCOORD_ALPHA, 2, GL_FLOAT, 0, 0, [self quedTextureAlphaData]);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD_ALPHA);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    if ([EAGLContext currentContext] == _context && !self.pause && self.window) {
        [_context presentRenderbuffer:GL_RENDERBUFFER];
    }
}

- (const void *)quedTextureAlphaData {

    switch (self.blendMode) {
        case QGHWDTextureBlendMode_AlphaLeft:
            return textureCoordLeft;
        case QGHWDTextureBlendMode_AlphaRight:
            return textureCoordRight;
        case QGHWDTextureBlendMode_AlphaTop:
            return textureCoordTop;
        case QGHWDTextureBlendMode_AlphaBottom:
            return textureCoordBottom;
        default:
            return textureCoordLeft;
    }
}

- (const void *)quadTextureRGBData {

    switch (self.blendMode) {
        case QGHWDTextureBlendMode_AlphaLeft:
            return textureCoordRight;
        case QGHWDTextureBlendMode_AlphaRight:
            return textureCoordLeft;
        case QGHWDTextureBlendMode_AlphaTop:
            return textureCoordBottom;
        case QGHWDTextureBlendMode_AlphaBottom:
            return textureCoordTop;
        default:
            return textureCoordRight;
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders {
    
    //QG_Info(MODULE_DECODE, @"loadShaders");
    GLuint vertShader, fragShader;
    
    self.program = glCreateProgram();
    
    // Create and compile the vertex shader.
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:kVertexShaderSource]) {
        //QG_Event(MODULE_DECODE,@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:kFragmentShaderSource]) {
        //QG_Event(MODULE_DECODE,@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(self.program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(self.program, fragShader);
    
    // Bind attribute locations. This needs to be done prior to linking.
    glBindAttribLocation(self.program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(self.program, ATTRIB_TEXCOORD_RGB, "RGBTexCoord");
    glBindAttribLocation(self.program, ATTRIB_TEXCOORD_ALPHA, "alphaTexCoord");
    
    // Link the program.
    if (![self linkProgram:self.program]) {
        //QG_Event(MODULE_DECODE,@"Failed to link program: %d", self.program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (self.program) {
            glDeleteProgram(self.program);
            self.program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_Y] = glGetUniformLocation(self.program, "SamplerY");
    uniforms[UNIFORM_UV] = glGetUniformLocation(self.program, "SamplerUV");
    uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(self.program, "colorConversionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(self.program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(self.program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(const NSString *)sourceString {
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"MODULE_DECODE Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL {
    
    //QG_Info(MODULE_DECODE, @"compileShader");
    NSError *error;
    NSString *sourceString = [[NSString alloc] initWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
        //QG_Event(MODULE_DECODE,@"Failed to load vertex shader: %@", [error localizedDescription]);
        return NO;
    }
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        //QG_Info(MODULE_DECODE,@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog {
    
    //QG_Info(MODULE_DECODE, @"link program");
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        //QG_Info(MODULE_DECODE,@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog {
    
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        //QG_Info(MODULE_DECODE,@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        //QG_Event(MODULE_DECODE, @"program is not valid:%@",@(status));
        return NO;
    }
    //QG_Info(MODULE_DECODE, @"programe is valid");
    return YES;
}


@end
