//
//  GifDisplayViewController.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/6.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "GifDisplayViewController.h"
#import "YYAnimatedImageView.h"
#import "YYImage.h"
#import "GifImage.h"
#import "SingletonOption.h"

@interface GifDisplayViewController ()

@property (weak, nonatomic) IBOutlet YYAnimatedImageView *yyAnimatedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
//@property (nonatomic, strong) GifImage *gifImage;

@end

@implementation GifDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([SingletonOption sharedInstance].useYYImage) {
        _yyAnimatedImageView.image = [YYImage imageNamed:@"niconiconi"];
        _yyAnimatedImageView.runloopMode = NSDefaultRunLoopMode;
    } else {
//        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"niconiconi@2x" withExtension:@"gif"];
//        _imageView.image = [UIImage animatedImageWithAnimatedGIFURL:URL];
//        [_imageView startAnimating];
        _imageView.image = [GifImage gifImageName:@"niconiconi"];
        
//        GifImage *gifImage = [GifImage imageNamed:@"niconiconi"];
//        //_gifImage = gifImage;
//        NSMutableArray *aimatedImages = [NSMutableArray array];
//        NSTimeInterval duration = 0;
//        for (int i = 0; i < gifImage.animatedImageFrameCount; i++) {
//            duration += [gifImage animatedImageDurationAtIndex:i];
//            [aimatedImages addObject:[gifImage animatedImageFrameAtIndex:i]];
//        }
//        _imageView.animationImages = aimatedImages;
//        _imageView.animationDuration = duration;
//        [_imageView startAnimating];
    }
}
- (IBAction)startOrStopAnimationAction:(UIBarButtonItem *)sender {
    _imageView.animating ? [_imageView stopAnimating] : [_imageView startAnimating];
    _yyAnimatedImageView.animating ? [_yyAnimatedImageView startAnimating] : [_yyAnimatedImageView stopAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
