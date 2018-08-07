//
//  ImageFrame.h
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Dispose method specifies how the area used by the current frame is to be treated
 before rendering the next frame on the canvas.
 */
typedef NS_ENUM(NSUInteger, ImageDisposeMethod) {
    /// No disposal is done on this frame before rendering the next; the contents of the canvas are left as is.
    ImageDisposeNone = 0,
    /// The frame's region of the canvas is to be cleared to fully transparent black before rendering the next frame.
    ImageDisposeBackground,
    /// The frame's region of the canvas is to be reverted to the previous contents before rendering the next frame.
    ImageDisposePrevious,
};

/**
 Blend operation specifies how transparent pixels of the current frame are
 blended with those of the previous canvas.
 */
typedef NS_ENUM(NSUInteger, ImageBlendOperation) {
    /// All color components of the frame, including alpha, overwrite the current contents of the frame's canvas region.
    ImageBlendNone = 0,
    /// The frame should be composited onto the output buffer based on its alpha.
    ImageBlendOver,
};

@interface ImageFrame : NSObject <NSCopying>

/// Frame index (zero based)
@property (nonatomic, assign) NSUInteger index;
// Frame pixel size
@property (nonatomic, assign) NSUInteger pixelWidth;
@property (nonatomic, assign) NSUInteger pixelHeight;
// Frame origin in canvas (left-bottom based)
@property (nonatomic, assign) NSUInteger pixelOffsetX;
@property (nonatomic, assign) NSUInteger pixelOffsetY;
/// Frame duration in seconds
@property (nonatomic, assign) NSTimeInterval duration;
/// Frame dispose method.
@property (nonatomic, assign) ImageDisposeMethod dispose;
/// Frame blend operation.
@property (nonatomic, assign) ImageBlendOperation blend;
/// The image.
@property (nonatomic, strong) UIImage *image;
+ (instancetype)frameWithImage:(UIImage *)image;

@end

@interface ImageDecodeFrame : ImageFrame

/// Whether frame has alpha.
@property (nonatomic, assign) BOOL hasAlpha;
/// Whether frame fill the canvas.
@property (nonatomic, assign) BOOL isFullSize;
/// Blend from frame index to current frame.
@property (nonatomic, assign) NSUInteger blendFromIndex;

@end
