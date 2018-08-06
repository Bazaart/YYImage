//
//  ImageUtil.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "ImageUtil.h"
#import <Accelerate/Accelerate.h>

#define FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

NS_INLINE CGFloat radiansWithDegrees(CGFloat degrees) {
    return degrees * M_PI / 180;
}

NS_INLINE size_t byteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

NS_INLINE void ImageCGDataProviderReleaseDataCallback(void *info, const void *data, size_t size) {
    if (info) free(info);
}

@implementation ImageUtil

+ (uint32_t)intIdWithInt0:(int)int0 int1:(int)int1 int2:(int)int2 int3:(int)int3 {
    uint32_t intId = (uint32_t)(int0 | (int1 << 8) | (int2 << 16) | (int3 << 24));
    return intId;
}
+ (uint32_t)intIdWithInt0:(int)int0 int1:(int)int1 {
    uint32_t intId = (uint32_t)(int0 | (int1 << 8));
    return intId;
}

+ (NSString *)detectTypeWithData:(CFDataRef)data {
    if (!data) return nil;
    uint64_t length = CFDataGetLength(data);
    if (length < 16) return nil;
    
    const char *bytes = (char *)CFDataGetBytePtr(data);
    
    uint32_t header4 = *((uint32_t *)bytes);
    switch (header4) {
        case FOUR_CC(0x4D, 0x4D, 0x00, 0x2A): { // big endian TIFF
        }
        case FOUR_CC(0x49, 0x49, 0x2A, 0x00): { // little endian TIFF
            return @"TIFF";
        } break;
        case FOUR_CC(0x00, 0x00, 0x01, 0x00): { // ICO
        }
        case FOUR_CC(0x00, 0x00, 0x02, 0x00): { // CUR
            return @"ICO";
        } break;
        case FOUR_CC('i', 'c', 'n', 's'): { // ICNS
            return @"ICNS";
        } break;
        case FOUR_CC('G', 'I', 'F', '8'): { // GIF
            return @"GIF";
        } break;
        case FOUR_CC(0x89, 'P', 'N', 'G'): {  // PNG
            uint32_t tmp = *((uint32_t *)(bytes + 4));
            if (tmp == FOUR_CC('\r', '\n', 0x1A, '\n')) {
                return @"PNG";
            }
        } break;
        case FOUR_CC('R', 'I', 'F', 'F'): { // WebP
            uint32_t tmp = *((uint32_t *)(bytes + 8));
            if (tmp == FOUR_CC('W', 'E', 'B', 'P')) {
                return @"WebP";
            }
        } break;
    }
    
    uint16_t header2 = *((uint16_t *)bytes);
    switch (header2) {
        case TWO_CC('B', 'A'):
        case TWO_CC('B', 'M'):
        case TWO_CC('I', 'C'):
        case TWO_CC('P', 'I'):
        case TWO_CC('C', 'I'):
        case TWO_CC('C', 'P'): { // BMP
            return @"BMP";
        }
        case TWO_CC(0xFF, 0x4F): { // JPEG2000
            return @"JPEG2000";
        }
    }
    
    // JPG             FF D8 FF
    if (memcmp(bytes,"\377\330\377",3) == 0) return @"JPEG";
    
    // JP2
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) return @"JPEG2000";
    
    return nil;
}

// TODO: 其他类型判断处理

+ (UIImageOrientation)orientationWithCGImagePropertyOrientation:(CGImagePropertyOrientation)inputOrientation {
    switch (inputOrientation) {
        case kCGImagePropertyOrientationUp: return UIImageOrientationUp;
        case kCGImagePropertyOrientationDown: return UIImageOrientationDown;
        case kCGImagePropertyOrientationLeft: return UIImageOrientationLeft;
        case kCGImagePropertyOrientationRight: return UIImageOrientationRight;
        case kCGImagePropertyOrientationUpMirrored: return UIImageOrientationUpMirrored;
        case kCGImagePropertyOrientationDownMirrored: return UIImageOrientationDownMirrored;
        case kCGImagePropertyOrientationLeftMirrored: return UIImageOrientationLeftMirrored;
        case kCGImagePropertyOrientationRightMirrored: return UIImageOrientationRightMirrored;
        default: return UIImageOrientationUp;
    }
}

+ (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    static CGColorSpaceRef space;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        space = CGColorSpaceCreateDeviceRGB();
    });
    return space;
}

+ (CGImageRef)createDecodedImageCopyWithImageRef:(CGImageRef)imageRef decodeForDisplay:(BOOL)decodeForDisplay {
    if (!imageRef) return NULL;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return NULL;
    
    if (decodeForDisplay) { //decode with redraw (may lose some precision)
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
        BOOL hasAlpha =
        alphaInfo == kCGImageAlphaPremultipliedLast ||
        alphaInfo == kCGImageAlphaPremultipliedFirst ||
        alphaInfo == kCGImageAlphaLast ||
        alphaInfo == kCGImageAlphaFirst;
        // BGRA8888 (premultiplied) or BGRX8888
        // same as UIGraphicsBeginImageContext() and -[UIView drawRect:]
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, [self colorSpaceGetDeviceRGB], bitmapInfo);
        if (!context) return NULL;
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode
        CGImageRef newImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        return newImage;
    } else {
        CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
        size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        if (bytesPerRow == 0 || width == 0 || height == 0) return NULL;
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
        if (!dataProvider) return NULL;
        CFDataRef data = CGDataProviderCopyData(dataProvider); // decode
        if (!data) return NULL;
        
        CGDataProviderRef newProvider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        if (!newProvider) return NULL;
        
        CGImageRef newImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, newProvider, NULL, false, kCGRenderingIntentDefault);
        CFRelease(newProvider);
        return newImage;
    }
}

+ (BOOL)canAnyFormatDecodeToBitmapBufferWithImageRef:(CGImageRef)imageRef targetImageBufer:(vImage_Buffer *)targetImageBufer targetFormat:(vImage_CGImageFormat *)targetFormat {
    if (!imageRef || (((long)vImageConvert_AnyToAny) + 1 == 1) || !targetFormat || !targetImageBufer) return NO;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return NO;
    targetImageBufer->data = NULL;
    
    vImage_Error error = kvImageNoError;
    CFDataRef srcData = NULL;
    vImageConverterRef convertor = NULL;
    vImage_CGImageFormat srcFormat = {0};
    srcFormat.bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(imageRef);
    srcFormat.bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(imageRef);
    srcFormat.colorSpace = CGImageGetColorSpace(imageRef);
    srcFormat.bitmapInfo = CGImageGetBitmapInfo(imageRef) | CGImageGetAlphaInfo(imageRef);
    
    BOOL (^failHandler)(void) = ^ {
        if (convertor) CFRelease(convertor);
        if (srcData) CFRelease(srcData);
        if (targetImageBufer->data) free(targetImageBufer->data);
        targetImageBufer->data = NULL;
        return NO;
    };
    
    convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, targetFormat, NULL, kvImageNoFlags, NULL);
    if (!convertor) return failHandler();
    
    CGDataProviderRef srcProvider = CGImageGetDataProvider(imageRef);
    srcData = srcProvider ? CGDataProviderCopyData(srcProvider) : NULL; // decode
    size_t srcLength = srcData ? CFDataGetLength(srcData) : 0;
    const void *srcBytes = srcData ? CFDataGetBytePtr(srcData) : NULL;
    if (srcLength == 0 || !srcBytes) return failHandler();
    
    vImage_Buffer src = {0};
    src.data = (void *)srcBytes;
    src.width = width;
    src.height = height;
    src.rowBytes = CGImageGetBytesPerRow(imageRef);
    
    error = vImageBuffer_Init(targetImageBufer, height, width, 32, kvImageNoFlags);
    if (error != kvImageNoError) return failHandler();
    
    error = vImageConvert_AnyToAny(convertor, &src, targetImageBufer, NULL, kvImageNoFlags); // convert
    if (error != kvImageNoError) return failHandler();
    
    CFRelease(convertor);
    CFRelease(srcData);
    return YES;
}

+ (BOOL)can32BitFormatDecodeToBitmapBufferWithImageRef:(CGImageRef)imageRef targetImageBufer:(vImage_Buffer *)targetImageBufer bitmapInfo:(CGBitmapInfo)bitmapInfo {
    if (!imageRef || !targetImageBufer) return NO;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return NO;
    
    BOOL hasAlpha = NO;
    BOOL alphaFirst = NO;
    BOOL alphaPremultiplied = NO;
    BOOL byteOrderNormal = NO;
    
    switch (bitmapInfo & kCGBitmapAlphaInfoMask) {
        case kCGImageAlphaPremultipliedLast: {
            hasAlpha = YES;
            alphaPremultiplied = YES;
        } break;
        case kCGImageAlphaPremultipliedFirst: {
            hasAlpha = YES;
            alphaPremultiplied = YES;
            alphaFirst = YES;
        } break;
        case kCGImageAlphaLast: {
            hasAlpha = YES;
        } break;
        case kCGImageAlphaFirst: {
            hasAlpha = YES;
            alphaFirst = YES;
        } break;
        case kCGImageAlphaNoneSkipLast: {
        } break;
        case kCGImageAlphaNoneSkipFirst: {
            alphaFirst = YES;
        } break;
        default: {
            return NO;
        } break;
    }
    
    switch (bitmapInfo & kCGBitmapByteOrderMask) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: {
            return NO;
        } break;
    }
    
    /*
     Try convert with vImageConvert_AnyToAny() (avaliable since iOS 7.0).
     If fail, try decode with CGContextDrawImage().
     CGBitmapContext use a premultiplied alpha format, unpremultiply may lose precision.
     */
    vImage_CGImageFormat destFormat = {0};
    destFormat.bitsPerComponent = 8;
    destFormat.bitsPerPixel = 32;
    destFormat.colorSpace = [self colorSpaceGetDeviceRGB];
    destFormat.bitmapInfo = bitmapInfo;
    targetImageBufer->data = NULL;
    if ([self canAnyFormatDecodeToBitmapBufferWithImageRef:imageRef targetImageBufer:targetImageBufer targetFormat:&destFormat]) return YES;
    
    CGBitmapInfo contextBitmapInfo = bitmapInfo & kCGBitmapByteOrderMask;
    if (!hasAlpha || alphaPremultiplied) {
        contextBitmapInfo |= (bitmapInfo & kCGBitmapAlphaInfoMask);
    } else {
        contextBitmapInfo |= alphaFirst ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaPremultipliedLast;
    }
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, [self colorSpaceGetDeviceRGB], contextBitmapInfo);
    
    BOOL (^failHandler)(void) = ^ {
        if (context) CFRelease(context);
        if (targetImageBufer->data) free(targetImageBufer->data);
        targetImageBufer->data = NULL;
        return NO;
    };
    
    if (!context) return failHandler();
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode and convert
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t length = height * bytesPerRow;
    void *data = CGBitmapContextGetData(context);
    if (length == 0 || !data) return failHandler();
    
    targetImageBufer->data = malloc(length);
    targetImageBufer->width = width;
    targetImageBufer->height = height;
    targetImageBufer->rowBytes = bytesPerRow;
    if (!targetImageBufer->data) return failHandler();
    
    if (hasAlpha && !alphaPremultiplied) {
        vImage_Buffer tmpSrc = {0};
        tmpSrc.data = data;
        tmpSrc.width = width;
        tmpSrc.height = height;
        tmpSrc.rowBytes = bytesPerRow;
        vImage_Error error;
        if (alphaFirst && byteOrderNormal) {
            error = vImageUnpremultiplyData_ARGB8888(&tmpSrc, targetImageBufer, kvImageNoFlags);
        } else {
            error = vImageUnpremultiplyData_RGBA8888(&tmpSrc, targetImageBufer, kvImageNoFlags);
        }
        if (error != kvImageNoError) return failHandler();
    } else {
        memcpy(targetImageBufer->data, data, length);
    }
    
    CFRelease(context);
    return YES;
}

+ (CGImageRef)createImageCopyWithImageRef:(CGImageRef)imageRef transform:(CGAffineTransform)transform targetSize:(CGSize)targetSize targetBitmapInfo:(CGBitmapInfo)targetBitmapInfo {
    if (!imageRef) return NULL;
    
    size_t srcWidth = CGImageGetWidth(imageRef);
    size_t srcHeight = CGImageGetHeight(imageRef);
    size_t targetWidth = round(targetSize.width);
    size_t targetHeight = round(targetSize.height);
    if (srcWidth == 0 || srcHeight == 0 || targetWidth == 0 || targetHeight == 0) return NULL;
    
    CGDataProviderRef tmpProvider = NULL, targetProvider = NULL;
    CGImageRef tmpImageRef = NULL, targetImageRef = NULL;
    vImage_Buffer src = {0}, tmp = {0}, target = {0};
    if (![self can32BitFormatDecodeToBitmapBufferWithImageRef:imageRef targetImageBufer:&src bitmapInfo:kCGImageAlphaFirst | kCGBitmapByteOrderDefault]) return NULL;
    
    size_t targetBytesPerRow = byteAlign(targetWidth * 4, 32);
    tmp.data = malloc(targetHeight * targetBytesPerRow);
    
    CGImageRef (^failHandler)(void) = ^ {
        if (src.data) free(src.data);
        if (tmp.data) free(tmp.data);
        if (target.data) free(target.data);
        if (tmpProvider) CFRelease(tmpProvider);
        if (tmpImageRef) CFRelease(tmpImageRef);
        if (targetProvider) CFRelease(targetProvider);
        return (CGImageRef)NULL;
    };
    
    if (!tmp.data) return failHandler();
    
    tmp.width = targetWidth;
    tmp.height = targetHeight;
    tmp.rowBytes = targetBytesPerRow;
    vImage_CGAffineTransform vTransform = *((vImage_CGAffineTransform *)&transform);
    uint8_t backgroundColor[4] = {0};
    vImage_Error error = vImageAffineWarpCG_ARGB8888(&src, &tmp, NULL, &vTransform, backgroundColor, kvImageBackgroundColorFill);
    if (error != kvImageNoError) return failHandler();
    free(src.data);
    src.data = NULL;
    
    tmpProvider = CGDataProviderCreateWithData(tmp.data, tmp.data, targetHeight * targetBytesPerRow, ImageCGDataProviderReleaseDataCallback);
    if (!tmpProvider) return failHandler();
    tmp.data = NULL; // hold by provider
    tmpImageRef = CGImageCreate(targetWidth, targetHeight, 8, 32, targetBytesPerRow, [self colorSpaceGetDeviceRGB], kCGImageAlphaFirst | kCGBitmapByteOrderDefault, tmpProvider, NULL, false, kCGRenderingIntentDefault);
    if (!tmpImageRef) return failHandler();
    CFRelease(tmpProvider);
    tmpProvider = NULL;
    
    if ((targetBitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaFirst &&
        (targetBitmapInfo & kCGBitmapByteOrderMask) != kCGBitmapByteOrder32Little) {
        return tmpImageRef;
    }
    
    if (![self can32BitFormatDecodeToBitmapBufferWithImageRef:tmpImageRef targetImageBufer:&target bitmapInfo:targetBitmapInfo]) return failHandler();
    CFRelease(tmpImageRef);
    tmpImageRef = NULL;
    
    targetProvider = CGDataProviderCreateWithData(target.data, target.data, targetHeight * targetBytesPerRow, ImageCGDataProviderReleaseDataCallback);
    if (!targetProvider) return failHandler();
    target.data = NULL; // hold by provider
    targetImageRef = CGImageCreate(targetWidth, targetWidth, 8, 32, targetBytesPerRow, [self colorSpaceGetDeviceRGB], targetBitmapInfo, targetProvider, NULL, false, kCGRenderingIntentDefault);
    if (!targetImageRef) return failHandler();
    CFRelease(targetProvider);
    targetProvider = NULL;
    
    return targetImageRef;
}

+ (CGImageRef)createImageCopyWithImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation)orientation targetBitmapInfo:(CGBitmapInfo)targetBitmapInfo {
    if (!imageRef) return NULL;
    if (orientation == UIImageOrientationUp) return (CGImageRef)CFRetain(imageRef);
    
    CGFloat width = (CGFloat)CGImageGetWidth(imageRef);
    CGFloat height = (CGFloat)CGImageGetHeight(imageRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    BOOL swapWidthAndHeight = NO;
    switch (orientation) {
        case UIImageOrientationDown:{
            transform = CGAffineTransformMakeRotation(radiansWithDegrees(180));
            transform = CGAffineTransformTranslate(transform, -width, -height);
        } break;
        case UIImageOrientationLeft:{
            transform = CGAffineTransformMakeRotation(radiansWithDegrees(90));
            transform = CGAffineTransformTranslate(transform, 0, -height);
            swapWidthAndHeight = YES;
        } break;
        case UIImageOrientationRight:{
            transform = CGAffineTransformMakeRotation(radiansWithDegrees(-90));
            transform = CGAffineTransformTranslate(transform, -width, 0);
            swapWidthAndHeight =  YES;
        } break;
        case UIImageOrientationUpMirrored:{
            transform = CGAffineTransformTranslate(transform, width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
        } break;
        case UIImageOrientationDownMirrored:{
            transform = CGAffineTransformTranslate(transform, 0, height);
            transform = CGAffineTransformScale(transform, 1, -1);
        } break;
        case UIImageOrientationLeftMirrored:{
            transform = CGAffineTransformMakeRotation(radiansWithDegrees(-90));
            transform = CGAffineTransformScale(transform, 1, -1);
            transform = CGAffineTransformTranslate(transform, -width, -height);
            swapWidthAndHeight = YES;
        } break;
        case UIImageOrientationRightMirrored:{
            transform = CGAffineTransformMakeRotation(radiansWithDegrees(90));
            transform = CGAffineTransformScale(transform, 1, -1);
            swapWidthAndHeight = YES;
        } break;
        default:{} break;
    }
    if (CGAffineTransformIsIdentity(transform)) return (CGImageRef)CFRetain(imageRef);
    
    CGSize targetSize = swapWidthAndHeight ? CGSizeMake(height, width) : CGSizeMake(width, height);
    return [self createImageCopyWithImageRef:imageRef transform:transform targetSize:targetSize targetBitmapInfo:targetBitmapInfo];
}

/**
 An array of NSNumber objects, shows the best order for path scale search.
 e.g. iPhone3GS:@[@1,@2,@3] iPhone5:@[@2,@3,@1]  iPhone6 Plus:@[@3,@2,@1]
 */
+ (NSArray *)bundlePreferredScales {
    static NSArray *scales;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat screenScale = [UIScreen mainScreen].scale;
        if (screenScale <= 1) {
            scales = @[@1,@2,@3];
        } else if (screenScale <= 2) {
            scales = @[@2,@3,@1];
        } else {
            scales = @[@3,@2,@1];
        }
    });
    return scales;
}

+ (CGFloat)scaleOfFileName:(NSString *)fileName {
    if (fileName.length == 0 || [fileName hasSuffix:@"/"]) return 1;
    NSString *name = fileName.stringByDeletingPathExtension;
    __block CGFloat scale = 1;
    
    NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+\\.?[0-9]*x$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [pattern enumerateMatchesInString:name options:kNilOptions range:NSMakeRange(0, name.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location >= 3) {
            scale = [fileName substringWithRange:NSMakeRange(result.range.location + 1, result.range.length - 2)].doubleValue;
        }
    }];
    
    return scale;
}

@end
