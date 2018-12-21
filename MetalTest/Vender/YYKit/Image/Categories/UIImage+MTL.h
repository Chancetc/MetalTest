//
//  UIImage+MTL.h
//  MetalTest
//
//  Created by Chanceguo on 2018/12/21.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (MTL)

- (id<MTLTexture>)textureForImage:(UIImage *)image withDevice:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
