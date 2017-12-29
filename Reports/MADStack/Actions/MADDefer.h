//
//  MADDefer.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/24/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADDefer_h
#define MAD_Designer_MADDefer_h

#import <Foundation/NSObject.h>

@interface MADDefer : NSObject

    @property (copy, nonatomic) void (^block)(void);
    + (instancetype)defer:(void (^)(void))block;

@end

void defer(void (^block)(void));

#endif
