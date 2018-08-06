//
//  GifEncodeViewController.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/6.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "GifEncodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GifImageEncoder.h"

static const CGFloat kFrameInterval = 0.1;
static const NSInteger kFrameCount = 20;

@interface GifEncodeViewController ()

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) NSArray *captureTimes;

@end

@implementation GifEncodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _videoURL = [NSURL URLWithString:@"https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4"];
    // offline
    //_videoURL = [[NSBundle mainBundle] URLForResource:@"local" withExtension:@"mp4"];
    
    _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:[AVAsset assetWithURL:_videoURL]];
    _imageGenerator.requestedTimeToleranceBefore = _imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    //    _imageGenerator.maximumSize = CGSizeMake(120, 120);
    
    CGFloat startTime = 23;
    CGFloat frameInterval = kFrameInterval;
    NSInteger frameCount = kFrameCount;
    NSMutableArray *times = [NSMutableArray array];
    for (int i = 0; i < frameCount; i++) {
        CMTime time = CMTimeMake(100.0 * (startTime + frameInterval * i), 1 * 100);
        [times addObject:[NSValue valueWithCMTime:time]];
    }
    _captureTimes = times.copy;
    
    
    [self captureAndEncodeGif];
}

- (void)createGifImageWithImages:(NSArray *)images {
    GifImageEncoder *encoder = [[GifImageEncoder alloc] init];
    for (UIImage *image in images) {
        [encoder addImage:image duration:kFrameInterval];
    }
    NSString *fileName = [NSString stringWithFormat:@"%@_gif.gif", @([NSDate date].timeIntervalSince1970)];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    BOOL writeSuccess = [encoder encodeToFile:path];
    NSLog(@"write %@", writeSuccess ? @"success" : @"fail");
}

- (void)captureAndEncodeGif {
    NSLog(@"开始截图");
    NSMutableArray *frameImages = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [_imageGenerator generateCGImagesAsynchronouslyForTimes:_captureTimes completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        UIImage *frameImage = [UIImage imageWithCGImage:image];
        //NSLog(@"image: %@, %@", frameImage, @(CMTimeGetSeconds(actualTime)));
        [frameImages addObject:frameImage];
        
        if (frameImages.count == kFrameCount) {
            NSLog(@"截图完成，开始生成 GIF");
            [weakSelf createGifImageWithImages:frameImages.copy];
        }
    }];
}

- (IBAction)captureAndEncodeAction:(UIBarButtonItem *)sender {
    [self captureAndEncodeGif];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
