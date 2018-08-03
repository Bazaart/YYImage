//
//  UIImage+ImageCoder.h
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageCoder)

/**
 Decompress this image to bitmap, so when the image is displayed on screen,
 the main thread won't be blocked by additional decode. If the image has already
 been decoded or unable to decode, it just returns itself.
 
 @return an image decoded, or just return itself if no needed.
 @see yy_isDecodedForDisplay
 */
//- (instancetype)imageByDecoded;

/**
 Wherher the image can be display on screen without additional decoding.
 @warning It just a hint for your code, change it has no other effect.
 */
@property (nonatomic) BOOL decodedForDisplay;

/**
 Saves this image to iOS Photos Album.
 
 @discussion  This method attempts to save the original data to album if the
 image is created from an animated GIF/APNG, otherwise, it will save the image
 as JPEG or PNG (based on the alpha information).
 
 @param completionBlock The block invoked (in main thread) after the save operation completes.
 assetURL: An URL that identifies the saved image file. If the image is not saved, assetURL is nil.
 error: If the image is not saved, an error object that describes the reason for failure, otherwise nil.
 */
//- (void)saveToAlbumWithCompletionBlock:(nullable void(^)(NSURL * _Nullable assetURL, NSError * _Nullable error))completionBlock;

/**
 Return a 'best' data representation for this image.
 
 @discussion The convertion based on these rule:
 1. If the image is created from an animated GIF/APNG/WebP, it returns the original data.
 2. It returns PNG or JPEG(0.9) representation based on the alpha information.
 
 @return Image data, or nil if an error occurs.
 */
//- (nullable NSData *)imageDataRepresentation;

@end
