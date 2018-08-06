//
//  VideoFrameViewController.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "VideoFrameViewController.h"
#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "FrameImageCollectionViewController.h"
#import "GifImageEncoder.h"

static NSString * const kImageKey = @"image";
static NSString * const kFrameDurationKey = @"duration";

static const CGFloat kFrameInterval = 0.1;
static const NSInteger kFrameCount = 10;

@interface VideoFrameViewController ()

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) NSArray *captureTimes;

@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (nonatomic, strong) FrameImageCollectionViewController *frameImageController;
@property (nonatomic, strong) NSArray *frameImages;
@property (weak, nonatomic) IBOutlet UIImageView *animatedImageView;

@end

@implementation VideoFrameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _videoURL = [NSURL URLWithString:@"https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4"];
    // offline
    _videoURL = [[NSBundle mainBundle] URLForResource:@"local" withExtension:@"mp4"];
    
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
    
    
//    NSError *error = nil;
//    _iamgeView.image = [UIImage imageWithCGImage:[_imageGenerator copyCGImageAtTime:CMTimeMake(100, 1) actualTime:NULL error:&error]];
//    if (error) {
//        NSLog(@"error: %@", error);
//    }
    [self captureFrameImage];
}

- (void)loadVideo {
    AVPlayer *player = [AVPlayer playerWithURL:_videoURL];
    _playerView.player = player;
}

- (void)captureFrameImage {
    NSMutableArray *frameDurations = [NSMutableArray array];
    NSMutableArray *frameImages = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    __block NSTimeInterval lastTime = -1;
    [_imageGenerator generateCGImagesAsynchronouslyForTimes:_captureTimes completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        UIImage *frameImage = [UIImage imageWithCGImage:image];
        NSLog(@"image: %@, %@", frameImage, @(CMTimeGetSeconds(actualTime)));
        [frameImages addObject:frameImage];
        if (lastTime > 0) [frameDurations addObject:@(CMTimeGetSeconds(actualTime) - lastTime)];
        if (lastTime < 0) lastTime = CMTimeGetSeconds(actualTime);
        else lastTime = CMTimeGetSeconds(actualTime);
        //weakSelf.frameImageController.frameImages = frameImages;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.frameImageController.collectionView reloadData];
            if (frameImages.count == kFrameCount) {
                weakSelf.frameImages = frameImages.copy;
                [weakSelf showAnimatedImage];
                [weakSelf createGifImage];
            }
        });
    }];
}

- (void)showAnimatedImage {
    _animatedImageView.animationImages = self.frameImages;
    _animatedImageView.animationDuration = kFrameInterval * kFrameCount;
    [_animatedImageView startAnimating];
}

- (void)createGifImage {
    GifImageEncoder *encoder = [[GifImageEncoder alloc] init];
    for (UIImage *image in _frameImages) {
        [encoder addImage:image duration:kFrameInterval];
    }
    NSString *fileName = [NSString stringWithFormat:@"%@_gif.gif", @([NSDate date].timeIntervalSince1970)];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
//    NSData *imageData = [encoder encode];
//    BOOL writeSuccess = [imageData writeToFile:path atomically:YES];
    BOOL writeSuccess = [encoder encodeToFile:path];
    NSLog(@"write %@", writeSuccess ? @"success" : @"fail");
    @autoreleasepool {
        _frameImages = nil;
    }
}

- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
    if (!_playerView.player) {
        [self loadVideo];
    } else if (_playerView.player.rate == 0.0) {
        [_playerView.player play];
    } else {
        [_playerView.player pause];
    }
}

- (IBAction)captureFrameImage:(UIBarButtonItem *)sender {
    [self captureFrameImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[FrameImageCollectionViewController class]]) {
        _frameImageController = segue.destinationViewController;
    }
}

@end
