//
//  ImageFrame.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "ImageFrame.h"

@implementation ImageFrame

+ (instancetype)frameWithImage:(UIImage *)image {
    ImageFrame *frame = [[self alloc] init];
    frame.image = image;
    return frame;
}

- (id)copyWithZone:(NSZone *)zone {
    ImageFrame *frame = [[self.class allocWithZone:zone] init];
    frame.index = _index;
    frame.pixelWidth = _pixelWidth;
    frame.pixelHeight = _pixelHeight;
    frame.pixelOffsetX = _pixelOffsetX;
    frame.pixelOffsetY = _pixelOffsetY;
    frame.duration = _duration;
    frame.dispose = _dispose;
    frame.blend = _blend;
    frame.image = _image.copy;
    return frame;
}

@end

@implementation ImageDecodeFrame

- (id)copyWithZone:(NSZone *)zone {
    ImageDecodeFrame *frame = [super copyWithZone:zone];
    frame.hasAlpha = _hasAlpha;
    frame.isFullSize = _isFullSize;
    frame.blendFromIndex = _blendFromIndex;
    return frame;
}

@end
