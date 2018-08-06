//
//  ViewController.m
//  GifImageDemo
//
//  Created by bqlin on 2018/8/2.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import "ViewController.h"
#import "SingletonOption.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)switchAction:(UISwitch *)sender {
    [SingletonOption sharedInstance].useYYImage = sender.on;
}

@end
