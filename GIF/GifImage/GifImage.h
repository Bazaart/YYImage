//
//  GifImage.h
//  GifImageDemo
//
//  Created by bqlin on 2018/8/6.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GifImage : UIImage

+ (instancetype)imageNamed:(NSString *)name;
+ (instancetype)imageWithContentsOfFile:(NSString *)path;
+ (instancetype)imageWithData:(NSData *)data;
+ (instancetype)imageWithData:(NSData *)data scale:(CGFloat)scale;

/**
 If the image is created from animated image data (multi-frame GIF/APNG/WebP),
 this property stores the original image data.
 */
@property (nonatomic, strong, readonly) NSData *animatedImageData;

/// Total animated frame count.
/// It the frame count is less than 1, then the methods below will be ignored.
@property (nonatomic, assign, readonly) NSUInteger animatedImageFrameCount;

/// Animation loop count, 0 means infinite looping.
@property (nonatomic, assign, readonly) NSUInteger animatedImageLoopCount;

/// Returns the frame image from a specified index.
/// This method may be called on background thread.
/// @param index  Frame index (zero based).
- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index;

/// Returns the frames's duration from a specified index.
/// @param index  Frame index (zero based).
- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index;

/// Use GifImage to decode GIF and return UIImage instance
+ (UIImage *)gifImageName:(NSString *)name;

@end
