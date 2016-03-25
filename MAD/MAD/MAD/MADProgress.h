//
//  MADProgress.h
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADProgress : NSObject <NSCopying>

    - (instancetype)initWithMessage:(NSString *)message andProgress:(float)progress;

    @property (nonatomic, copy, readonly) NSString *message;
    @property (nonatomic, assign, readonly) float progress;

@end
