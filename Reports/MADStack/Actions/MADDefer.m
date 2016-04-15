//
//  MADDefer.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#if __has_feature(objc_arc)
#warning Compile this file with ARC using the -fno-objc-arc flag.
#endif

#import "MADDefer.h"

@implementation MADDefer

+ (instancetype)defer:(void (^)())block {
    MADDefer *defer =  [[MADDefer alloc] init];
    defer.block = block;
    return [defer autorelease];
}

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    if (_block)
        _block();
    [super dealloc];
}

@end

void madDefer(void (^block)()) {
    static MADDefer *d;
    d = [MADDefer defer:block];
}
