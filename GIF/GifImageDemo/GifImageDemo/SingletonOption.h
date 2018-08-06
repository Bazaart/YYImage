//
//  SingletonOption.h
//  GifImageDemo
//
//  Created by bqlin on 2018/8/6.
//  Copyright © 2018年 Bq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingletonOption : NSObject

@property (nonatomic, assign) BOOL useYYImage;

+ (instancetype)sharedInstance;

@end
