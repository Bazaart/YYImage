//
//  GifImageCodec.h
//  GifImageDemo
//
//  Created by bqlin on 2018/8/2.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageFrame.h"

@interface GifImageDecoder : NSObject

/// Image data
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, assign, readonly) CGFloat scale;
@property (nonatomic, assign, readonly) NSUInteger frameCount;
@property (nonatomic, assign, readonly) NSUInteger loopCount;
//@property (nonatomic, assign, readonly) CGSize size;
@property (nonatomic, readonly) NSUInteger pixelWidth; // TODO: -> pixelWidth
@property (nonatomic, readonly) NSUInteger pixelHeight; // TODO: -> pixelHeight
@property (nonatomic, assign, readonly) BOOL finalized;

/**
 Creates an image decoder.
 
 @param scale  Image's scale.
 @return An image decoder.
 */
- (instancetype)initWithScale:(CGFloat)scale NS_DESIGNATED_INITIALIZER;

/**
 Updates the incremental image with new data.
 
 @discussion You can use this method to decode progressive/interlaced/baseline
 image when you do not have the complete image data. The `data` was retained by
 decoder, you should not modify the data in other thread during decoding.
 
 @param data  The data to add to the image decoder. Each time you call this
 function, the 'data' parameter must contain all of the image file data
 accumulated so far.
 
 @param final  A value that specifies whether the data is the final set.
 Pass YES if it is, NO otherwise. When the data is already finalized, you can
 not update the data anymore.
 
 @return Whether succeed.
 */
- (BOOL)updateData:(NSData *)data final:(BOOL)final;

/**
 Convenience method to create a decoder with specified data.
 @param data  Image data.
 @param scale Image's scale.
 @return A new decoder, or nil if an error occurs.
 */
+ (instancetype)decoderWithData:(NSData *)data scale:(CGFloat)scale;

/**
 Decodes and returns a frame from a specified index.
 @param index  Frame image index (zero-based).
 @param decodeForDisplay Whether decode the image to memory bitmap for display.
 If NO, it will try to returns the original frame data without blend.
 @return A new frame with image, or nil if an error occurs.
 */
- (ImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay;

/**
 Returns the frame duration from a specified index.
 @param index  Frame image (zero-based).
 @return Duration in seconds.
 */
- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index;

/**
 Returns the frame's properties. See "CGImageProperties.h" in ImageIO.framework
 for more information.
 
 @param index  Frame image index (zero-based).
 @return The ImageIO frame property.
 */
- (NSDictionary *)framePropertiesAtIndex:(NSUInteger)index;

/**
 Returns the image's properties. See "CGImageProperties.h" in ImageIO.framework
 for more information.
 */
- (NSDictionary *)imageProperties;

@end
