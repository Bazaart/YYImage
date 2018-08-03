//
//  UIImage+ImageCoder.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "UIImage+ImageCoder.h"
#import <objc/runtime.h>

@implementation UIImage (ImageCoder)

//- (instancetype)imageByDecoded {
//    if (self.yy_isDecodedForDisplay) return self;
//    CGImageRef imageRef = self.CGImage;
//    if (!imageRef) return self;
//    CGImageRef newImageRef = YYCGImageCreateDecodedCopy(imageRef, YES);
//    if (!newImageRef) return self;
//    UIImage *newImage = [[self.class alloc] initWithCGImage:newImageRef scale:self.scale orientation:self.imageOrientation];
//    CGImageRelease(newImageRef);
//    if (!newImage) newImage = self; // decode failed, return self.
//    newImage.yy_isDecodedForDisplay = YES;
//    return newImage;
//}

- (BOOL)decodedForDisplay {
    if (self.images.count > 1) return YES;
    NSNumber *num = objc_getAssociatedObject(self, @selector(decodedForDisplay));
    return [num boolValue];
}

- (void)setDecodedForDisplay:(BOOL)isDecodedForDisplay {
    objc_setAssociatedObject(self, @selector(decodedForDisplay), @(isDecodedForDisplay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//- (void)saveToAlbumWithCompletionBlock:(void(^)(NSURL *assetURL, NSError *error))completionBlock {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSData *data = [self _yy_dataRepresentationForSystem:YES];
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error){
//            if (!completionBlock) return;
//            if (pthread_main_np()) {
//                completionBlock(assetURL, error);
//            } else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completionBlock(assetURL, error);
//                });
//            }
//        }];
//    });
//}

//- (NSData *)imageDataRepresentation {
//    return [self _dataRepresentationForSystem:NO];
//}
//
///// @param forSystem YES: used for system album (PNG/JPEG/GIF), NO: used for YYImage (PNG/JPEG/GIF/WebP)
//- (NSData *)_dataRepresentationForSystem:(BOOL)forSystem {
//    NSData *data = nil;
//    if ([self isKindOfClass:[YYImage class]]) {
//        YYImage *image = (id)self;
//        if (image.animatedImageData) {
//            if (forSystem) { // system only support GIF and PNG
//                if (image.animatedImageType == YYImageTypeGIF ||
//                    image.animatedImageType == YYImageTypePNG) {
//                    data = image.animatedImageData;
//                }
//            } else {
//                data = image.animatedImageData;
//            }
//        }
//    }
//    if (!data) {
//        CGImageRef imageRef = self.CGImage ? (CGImageRef)CFRetain(self.CGImage) : nil;
//        if (imageRef) {
//            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
//            CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
//            BOOL hasAlpha = NO;
//            if (alphaInfo == kCGImageAlphaPremultipliedLast ||
//                alphaInfo == kCGImageAlphaPremultipliedFirst ||
//                alphaInfo == kCGImageAlphaLast ||
//                alphaInfo == kCGImageAlphaFirst) {
//                hasAlpha = YES;
//            }
//            if (self.imageOrientation != UIImageOrientationUp) {
//                CGImageRef rotated = YYCGImageCreateCopyWithOrientation(imageRef, self.imageOrientation, bitmapInfo | alphaInfo);
//                if (rotated) {
//                    CFRelease(imageRef);
//                    imageRef = rotated;
//                }
//            }
//            @autoreleasepool {
//                UIImage *newImage = [UIImage imageWithCGImage:imageRef];
//                if (newImage) {
//                    if (hasAlpha) {
//                        data = UIImagePNGRepresentation([UIImage imageWithCGImage:imageRef]);
//                    } else {
//                        data = UIImageJPEGRepresentation([UIImage imageWithCGImage:imageRef], 0.9); // same as Apple's example
//                    }
//                }
//            }
//            CFRelease(imageRef);
//        }
//    }
//    if (!data) {
//        data = UIImagePNGRepresentation(self);
//    }
//    return data;
//}

@end
