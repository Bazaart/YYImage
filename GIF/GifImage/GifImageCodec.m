//
//  GifImageCodec.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/2.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "GifImageCodec.h"
#import <pthread.h>
#import "ImageUtil.h"
#import "UIImage+ImageCoder.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation GifImageDecoder
{
    pthread_mutex_t _lock; // recursive lock
    
    CGImageSourceRef _source;
    
    UIImageOrientation _orientation;
    dispatch_semaphore_t _framesLock;
    NSArray *_frames; ///< Array<GGImageDecoderFrame>, without image
    BOOL _needBlend;
    NSUInteger _blendFrameIndex;
    CGContextRef _blendCanvas;
}

- (void)dealloc {
    if (_source) CFRelease(_source);
    if (_blendCanvas) CFRelease(_blendCanvas);
    pthread_mutex_destroy(&_lock);
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - convenience

+ (instancetype)decoderWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data) return nil;
    GifImageDecoder *decoder = [[GifImageDecoder alloc] initWithScale:scale];
    [decoder updateData:data final:YES];
    if (decoder.frameCount > 0) {
        return decoder;
    }
    return nil;
}


#pragma mark -

- (instancetype)init {
    return [self initWithScale:[UIScreen mainScreen].scale];
}

- (instancetype)initWithScale:(CGFloat)scale {
    if (self = [super init]) {
        if (scale <= 0) scale = 1;
        _scale = scale;
        // create lock
        _framesLock = dispatch_semaphore_create(1);
        
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &attr);
        pthread_mutexattr_destroy(&attr);
    }
    return self;
}

- (BOOL)updateData:(NSData *)data final:(BOOL)final {
    BOOL result = NO;
    pthread_mutex_lock(&_lock);
    result = [self _updateData:data final:final];
    pthread_mutex_unlock(&_lock);
    return result;
}

- (ImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay {
    ImageFrame *frame = nil;
    pthread_mutex_lock(&_lock);
    frame = [self _frameAtIndex:index decodeForDisplay:decodeForDisplay];
    pthread_mutex_unlock(&_lock);
    return frame;
}

- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index {
    NSTimeInterval frameDuration = 0;
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    if (index < _frames.count) {
        ImageDecodeFrame *frame = _frames[index];
        frameDuration = frame.duration;
    }
    dispatch_semaphore_signal(_framesLock);
    return frameDuration;
}

- (NSDictionary *)framePropertiesAtIndex:(NSUInteger)index {
    NSDictionary *frameProperties = nil;
    pthread_mutex_lock(&_lock);
    frameProperties = [self _framePropertiesAtIndex:index];
    pthread_mutex_unlock(&_lock);
    return frameProperties;
}

- (NSDictionary *)imageProperties {
    NSDictionary *imageProperties = nil;
    pthread_mutex_lock(&_lock);
    imageProperties = [self _imageProperties];
    pthread_mutex_unlock(&_lock);
    return imageProperties;
}

#pragma mark - private

- (NSDictionary *)_imageProperties {
    if (!_source) return nil;
    CFDictionaryRef properties = CGImageSourceCopyProperties(_source, NULL);
    if (!properties) return nil;
    return CFBridgingRelease(properties);
}

- (NSDictionary *)_framePropertiesAtIndex:(NSUInteger)index {
    if (index >= _frames.count) return nil;
    if (!_source) return nil;
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_source, index, NULL);
    if (!properties) return nil;
    return CFBridgingRelease(properties);
}

- (CGImageRef)_newUnblendedImageAtIndex:(NSUInteger)index extendToCanvas:(BOOL)extendToCanvas decoded:(BOOL *)decoded CF_RETURNS_RETAINED {
    if (!_finalized && index > 0) return NULL;
    if (_frames.count <= index) return NULL;
    //ImageDecodeFrame *frame = _frames[index];
    if (!_source) return NULL;
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_source, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
    if (imageRef && extendToCanvas) {
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        if (width == _width && height == _height) {
            CGImageRef imageRefExtended = [ImageUtil createDecodedImageCopyWithImageRef:imageRef decodeForDisplay:YES];
            if (imageRefExtended) {
                CFRelease(imageRef);
                imageRef = imageRefExtended;
                if (decoded) *decoded = YES;
            }
        } else {
            CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, [ImageUtil colorSpaceGetDeviceRGB], kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
            if (context) {
                // 添加位移逻辑
                CGContextDrawImage(context, CGRectMake(_width - width, _height - height, width, height), imageRef);
                CGImageRef imageRefExtended = CGBitmapContextCreateImage(context);
                CFRelease(context);
                if (imageRefExtended) {
                    CFRelease(imageRef);
                    imageRef = imageRefExtended;
                    if (decoded) *decoded = YES;
                }
            }
        }
    }
    return imageRef;
}

- (BOOL)_createBlendContextIfNeeded {
    if (!_blendCanvas) {
        _blendFrameIndex = NSNotFound;
        _blendCanvas = CGBitmapContextCreate(NULL, _width, _height, 8, 0, [ImageUtil colorSpaceGetDeviceRGB], kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    }
    return _blendCanvas != NULL;
}

- (void)_blendImageWithFrame:(ImageDecodeFrame *)frame {
    if (frame.dispose == ImageDisposePrevious) {
        // nothing
    } else if (frame.dispose == ImageDisposeBackground) {
        CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
    } else { // no dispose
        if (frame.blend == ImageBlendOver) {
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
        } else {
            CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
        }
    }
}

- (CGImageRef)_newBlendedImageWithFrame:(ImageDecodeFrame *)frame CF_RETURNS_RETAINED {
    CGImageRef imageRef = NULL;
    if (frame.dispose == ImageDisposePrevious) {
        if (frame.blend == ImageBlendOver) {
            CGImageRef previousImage = CGBitmapContextCreateImage(_blendCanvas);
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            CGContextClearRect(_blendCanvas, CGRectMake(0, 0, _width, _height));
            if (previousImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(0, 0, _width, _height), previousImage);
                CFRelease(previousImage);
            }
        } else {
            CGImageRef previousImage = CGBitmapContextCreateImage(_blendCanvas);
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            CGContextClearRect(_blendCanvas, CGRectMake(0, 0, _width, _height));
            if (previousImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(0, 0, _width, _height), previousImage);
                CFRelease(previousImage);
            }
        }
    } else if (frame.dispose == ImageDisposeBackground) {
        if (frame.blend == ImageBlendOver) {
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
        } else {
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
        }
    } else { // no dispose
        if (frame.blend == ImageBlendOver) {
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
        } else {
            CGImageRef unblendImage = [self _newUnblendedImageAtIndex:frame.index extendToCanvas:NO decoded:NULL];
            if (unblendImage) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendImage);
                CFRelease(unblendImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
        }
    }
    return imageRef;
}

- (ImageFrame *)_frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay {
    if (index >= _frames.count) return 0;
    ImageDecodeFrame *frame = [_frames[index] copy];
    BOOL decoded = NO;
    BOOL extendToCanvas = decodeForDisplay;
    
    if (!_needBlend) {
        CGImageRef imageRef = [self _newUnblendedImageAtIndex:index extendToCanvas:extendToCanvas decoded:&decoded];
        if (!imageRef) return nil;
        if (decodeForDisplay && !decoded) {
            CGImageRef imageRefDecoded = [ImageUtil createDecodedImageCopyWithImageRef:imageRef decodeForDisplay:YES];
            if (imageRefDecoded) {
                CFRelease(imageRef);
                imageRef = imageRefDecoded;
                decoded = YES;
            }
        }
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:_scale orientation:_orientation];
        CFRelease(imageRef);
        if (!image) return nil;
        image.decodedForDisplay = decoded;
        frame.image = image;
        return frame;
    }
    
    // blend
    if (![self _createBlendContextIfNeeded]) return nil;
    CGImageRef imageRef = NULL;
    
    if (_blendFrameIndex + 1 == frame.index) {
        imageRef = [self _newBlendedImageWithFrame:frame];
        _blendFrameIndex = index;
    } else { // should draw canvas from previous frame
        _blendFrameIndex = NSNotFound;
        CGContextClearRect(_blendCanvas, CGRectMake(0, 0, _width, _height));
        
        if (frame.blendFromIndex == frame.index) {
            CGImageRef unblendedImage = [self _newUnblendedImageAtIndex:index extendToCanvas:NO decoded:NULL];
            if (unblendedImage) {
                CGContextDrawImage(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight), unblendedImage);
                CFRelease(unblendedImage);
            }
            imageRef = CGBitmapContextCreateImage(_blendCanvas);
            if (frame.dispose == ImageDisposeBackground) {
                CGContextClearRect(_blendCanvas, CGRectMake(frame.pixelOffsetX, frame.pixelOffsetY, frame.pixelWidth, frame.pixelHeight));
            }
            _blendFrameIndex = index;
        } else { // canvas is not ready
            for (uint32_t i = (uint32_t)frame.blendFromIndex; i <= (uint32_t)frame.index; i++) {
                if (i == frame.index) {
                    if (!imageRef) imageRef = [self _newBlendedImageWithFrame:frame];
                } else {
                    [self _blendImageWithFrame:_frames[i]];
                }
            }
            _blendFrameIndex = index;
        }
    }
    
    if (!imageRef) return nil;
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:_scale orientation:_orientation];
    CFRelease(imageRef);
    if (!image) return nil;
    
    image.decodedForDisplay = YES;
    frame.image = image;
    if (extendToCanvas) {
        frame.pixelWidth = _width;
        frame.pixelHeight = _height;
        frame.pixelOffsetX = 0;
        frame.pixelOffsetY = 0;
        frame.dispose = ImageDisposeNone;
        frame.blend = ImageBlendNone;
    }
    return frame;
}

- (BOOL)_updateData:(NSData *)data final:(BOOL)final {
    if (_finalized) return NO;
    if (data.length < _data.length) return NO;
    _finalized = final;
    _data = data;
    
    // 忽略类型检测
    
    if (_data.length > 16) {
        [self _updateSource];
    }
    return YES;
}

- (void)_updateSource {
    // update source ImageIO
    _width = 0;
    _height = 0;
    _orientation = UIImageOrientationUp;
    _loopCount = 0;
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    _frames = nil;
    dispatch_semaphore_signal(_framesLock);
    
    if (!_source) {
        if (_finalized) {
            _source = CGImageSourceCreateWithData((__bridge CFDataRef)_data, NULL);
        } else {
            _source = CGImageSourceCreateIncremental(NULL);
            if (_source) CGImageSourceUpdateData(_source, (__bridge CFDataRef)_data, false);
        }
    } else {
        CGImageSourceUpdateData(_source, (__bridge CFDataRef)_data, _finalized);
    }
    if (!_source) return;
    
    _frameCount = CGImageSourceGetCount(_source);
    if (_frameCount == 0) return;
    
    if (!_finalized) { // ignore multi-frame before finalized
        _frameCount = 1;
    } else {
        // get gif loop count
        CFDictionaryRef properties = CGImageSourceCopyProperties(_source, NULL);
        if (properties) {
            CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            if (gif) {
                CFTypeRef loop = CFDictionaryGetValue(gif, kCGImagePropertyGIFLoopCount);
                if (loop) CFNumberGetValue(loop, kCFNumberNSIntegerType, &_loopCount);
            }
            CFRelease(properties);
        }
    }
    
    // ICO, GIF, APNG may contains multi-frame.
    NSMutableArray *frames = [NSMutableArray array];
    for (NSUInteger i = 0; i < _frameCount; i++) {
        ImageDecodeFrame *frame = [[ImageDecodeFrame alloc] init];
        frame.index = i;
        frame.blendFromIndex = i;
        frame.hasAlpha = YES;
        frame.isFullSize = YES;
        [frames addObject:frame];
        
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_source, i, NULL);
        if (properties) {
            NSTimeInterval duration = 0;
            NSInteger orientationValue = 0, width = 0, height = 0;
            CFTypeRef value = NULL;
            
            value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
            value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
            
            CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            if (gif) {
                // Use the unclamped frame delay if it exists.
                value = CFDictionaryGetValue(gif, kCGImagePropertyGIFUnclampedDelayTime);
                if (!value) {
                    // Fall back to the clamped frame delay if the unclamped frame delay does not exist.
                    value = CFDictionaryGetValue(gif, kCGImagePropertyGIFDelayTime);
                }
                if (value) CFNumberGetValue(value, kCFNumberDoubleType, &duration);
            }
            
            frame.pixelWidth = width;
            frame.pixelHeight = height;
            frame.duration = duration;
            
            if (i == 0) { // init first frame
                _width = width;
                _height = height;
                value = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                if (value) {
                    CFNumberGetValue(value, kCFNumberNSIntegerType, &orientationValue);
                    _orientation = [ImageUtil orientationWithCGImagePropertyOrientation:(CGImagePropertyOrientation)orientationValue];
                }
            }
            CFRelease(properties);
        }
    }
    dispatch_semaphore_wait(_framesLock, DISPATCH_TIME_FOREVER);
    _frames = frames;
    dispatch_semaphore_signal(_framesLock);
}

@end
