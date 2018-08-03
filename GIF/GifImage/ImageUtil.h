//
//  ImageUtil.h
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageUtil : NSObject

+ (UIImageOrientation)orientationWithCGImagePropertyOrientation:(CGImagePropertyOrientation)inputOrientation;

+ (CGColorSpaceRef)colorSpaceGetDeviceRGB;

+ (CGImageRef)createDecodedImageCopyWithImageRef:(CGImageRef)imageRef decodeForDisplay:(BOOL)decodeForDisplay;

+ (CGImageRef)createImageCopyWithImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation)orientation targetBitmapInfo:(CGBitmapInfo)targetBitmapInfo;

@end
