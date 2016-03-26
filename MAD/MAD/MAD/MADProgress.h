//
//  MADProgress.h
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADProgress_h
#define MAD_Designer_MADProgress_h

#import <Foundation/NSObject.h>

@interface MADProgress : NSObject <NSCopying>

    - (instancetype)initWithMessage:(NSString *)message andProgress:(float)progress;

    @property (nonatomic, copy, readonly) NSString *message;
    @property (nonatomic, assign, readonly) float progress;

@end

#endif
