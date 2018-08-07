//
//  GifImage.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/6.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "GifImage.h"
#import "ImageUtil.h"
#import "GifImageDecoder.h"
#import "UIImage+ImageCoder.h"

@implementation GifImage
{
    GifImageDecoder *_decoder;
}

+ (instancetype)imageNamed:(NSString *)name {
    if (name.length == 0) return nil;
    if ([name hasSuffix:@"/"]) return nil;
    
    NSString *fileName = name.stringByDeletingPathExtension;
    NSString *extension = name.pathExtension;
    NSString *path = nil;
    CGFloat scale = 1;
    
    // If no extension, guess by system supported (same as UIImage).
    NSArray *extensions = extension.length > 0 ? @[extension] : @[@"", @"png", @"jpeg", @"jpg", @"gif"];
    NSArray *scales = [ImageUtil bundlePreferredScales];
    for (int i = 0; i < scales.count; i++) {
        scale = [scales[i] floatValue];
        NSString *scaledName = [fileName stringByAppendingFormat:@"@%@x", @(scale)];
        for (NSString *extension in extensions) {
            path = [[NSBundle mainBundle] pathForResource:scaledName ofType:extension];
            if (path) break;
        }
        if (path) break;
    }
    if (path.length == 0) return nil;
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length == 0) return nil;
    
    return [[self alloc] initWithData:data scale:scale];
}

+ (instancetype)imageWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (instancetype)imageWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

+ (instancetype)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[self alloc] initWithData:data scale:scale];
}

+ (UIImage *)gifImageName:(NSString *)name {
    GifImage *gifImage = [self imageNamed:name];
    NSMutableArray *aimatedImages = [NSMutableArray array];
    NSTimeInterval duration = 0;
    for (int i = 0; i < gifImage.animatedImageFrameCount; i++) {
        duration += [gifImage animatedImageDurationAtIndex:i];
        [aimatedImages addObject:[gifImage animatedImageFrameAtIndex:i]];
    }
    return [UIImage animatedImageWithImages:aimatedImages duration:duration];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data scale:[ImageUtil scaleOfFileName:path.lastPathComponent]];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (data.length == 0) return nil;
    if (scale <= 0) scale = [UIScreen mainScreen].scale;
    @autoreleasepool {
        GifImageDecoder *decoder = [GifImageDecoder decoderWithData:data scale:scale];
        ImageFrame *frame = [decoder frameAtIndex:0 decodeForDisplay:YES];
        UIImage *image = frame.image;
        if (!image) return nil;
        self = [self initWithCGImage:image.CGImage scale:decoder.scale orientation:image.imageOrientation];
        if (!self) return nil;
        if (decoder.frameCount > 1) {
            _decoder = decoder;
        }
        self.decodedForDisplay = YES;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

#pragma mark - property

- (NSData *)animatedImageData {
    return _decoder.data;
}

- (NSUInteger)animatedImageFrameCount {
    return _decoder.frameCount;
}

- (NSUInteger)animatedImageLoopCount {
    return _decoder.loopCount;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (index >= _decoder.frameCount) return nil;
    return [_decoder frameAtIndex:index decodeForDisplay:YES].image;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    NSTimeInterval duration = [_decoder frameDurationAtIndex:index];
    if (duration < 0.011f) return 0.100f;
    return duration;
}

@end
