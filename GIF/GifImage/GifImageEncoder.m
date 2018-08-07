//
//  GifImageEncoder.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/6.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "GifImageEncoder.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ImageUtil.h"

@implementation GifImageEncoder
{
    NSMutableArray *_images, *_durations;
}

- (void)dealloc {}

- (instancetype)init {
    if (self = [super init]) {
        _images = [NSMutableArray array];
        _durations = [NSMutableArray array];
    }
    return self;
}

- (void)addImage:(UIImage *)image duration:(NSTimeInterval)duration {
    if (!image.CGImage) return;
    duration = duration < 0 ? 0 : duration;
    [_images addObject:image];
    [_durations addObject:@(duration)];
}

- (void)addImageWithData:(NSData *)data duration:(NSTimeInterval)duration {
    if (data.length == 0) return;
    duration = duration < 0 ? 0 : duration;
    [_images addObject:data];
    [_durations addObject:@(duration)];
}

- (void)addImageWithFile:(NSString *)path duration:(NSTimeInterval)duration {
    if (path.length == 0) return;
    duration = duration < 0 ? 0 : duration;
    NSURL *URL = [NSURL fileURLWithPath:path];
    if (!URL) return;
    [_images addObject:URL];
    [_durations addObject:@(duration)];
}

- (NSData *)encode {
    if (_images.count == 0) return nil;
    
    NSMutableData *data = [NSMutableData data];
    NSUInteger count = _images.count;
    CGImageDestinationRef destination = [self _newImageDestination:data imageCount:count];
    BOOL success = NO;
    if (destination) {
        [self _encodeImageWithDestination:destination imageCount:count];
        success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
    if (success && data.length > 0) {
        return data;
    } else {
        return nil;
    }
}

- (BOOL)encodeToFile:(NSString *)path {
    NSUInteger count = _images.count;
    CGImageDestinationRef destination = [self _newImageDestination:path imageCount:count];
    BOOL success = NO;
    if (destination) {
        [self _encodeImageWithDestination:destination imageCount:count];
        success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
    return success;
}

#pragma mark - private

- (CGImageDestinationRef)_newImageDestination:(id)dest imageCount:(NSUInteger)count CF_RETURNS_RETAINED {
    if (!dest) return nil;
    CGImageDestinationRef destination = NULL;
    if ([dest isKindOfClass:[NSString class]]) {
        NSURL *URL = [NSURL fileURLWithPath:dest];
        if (URL) {
            destination = CGImageDestinationCreateWithURL((CFURLRef)URL, kUTTypeGIF, count, NULL);
        }
    } else if ([dest isKindOfClass:[NSMutableData class]]) {
        destination = CGImageDestinationCreateWithData((CFMutableDataRef)dest, kUTTypeGIF, count, NULL);
    }
    return destination;
}

- (void)_encodeImageWithDestination:(CGImageDestinationRef)destination imageCount:(NSUInteger)count {
    NSDictionary *gifProperty =
    @{
      (__bridge id)kCGImagePropertyGIFDictionary:
          @{
              (__bridge id)kCGImagePropertyGIFLoopCount: @(_loopCount)
              }
      };
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperty);
    
    for (int i = 0; i < count; i++) {
        @autoreleasepool {
            id imageSrc = _images[i];
            NSDictionary *frameProperty = nil;
            if (count > 1) frameProperty =
                @{
                  (__bridge id)kCGImagePropertyGIFDictionary:
                      @{
                          (__bridge id)kCGImagePropertyGIFDelayTime: _durations[i]
                          }
                  };
            
            if ([imageSrc isKindOfClass:[UIImage class]]) {
                UIImage *image = imageSrc;
                // !!!: 若不处理图片方向，此逻辑可跳过
                if (image.imageOrientation != UIImageOrientationUp && image.CGImage) {
                    CGBitmapInfo info = CGImageGetBitmapInfo(image.CGImage) | CGImageGetAlphaInfo(image.CGImage);
                    CGImageRef rotatedImageRef = [ImageUtil createImageCopyWithImageRef:image.CGImage orientation:image.imageOrientation targetBitmapInfo:info];
                    if (rotatedImageRef) {
                        image = [UIImage imageWithCGImage:rotatedImageRef];
                        CFRelease(rotatedImageRef);
                    }
                }
                if (image.CGImage) CGImageDestinationAddImage(destination, image.CGImage, (CFDictionaryRef)frameProperty);
            } else if ([imageSrc isKindOfClass:[NSURL class]]) {
                CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)imageSrc, NULL);
                if (source) {
                    CGImageDestinationAddImageFromSource(destination, source, 0, (CFDictionaryRef)frameProperty);
                    CFRelease(source);
                }
            } else if ([imageSrc isKindOfClass:[NSData class]]) {
                CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageSrc, NULL);
                if (source) {
                    CGImageDestinationAddImageFromSource(destination, source, 0, (CFDictionaryRef)frameProperty);
                    CFRelease(source);
                }
            }
        }
    }
}

@end
