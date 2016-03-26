//
//  MADDefer.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADDefer_h
#define MAD_Designer_MADDefer_h

#import <Foundation/NSObject.h>

@interface MADDefer : NSObject

    @property (copy, nonatomic) void (^block)();
    + (instancetype)defer:(void (^)())block;

@end

void defer(void (^block)());

#endif
