//
//  PlayerView.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/3.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerView ()

@end

@implementation PlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)self.layer player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [(AVPlayerLayer *)self.layer setPlayer:player];
}

@end
