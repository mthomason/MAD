//
//  MADDefer.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#if __has_feature(objc_arc)
    #warning Do not use ARC in this file.
#endif

#import "MADDefer.h"

@implementation MADDefer

+ (instancetype)defer:(void (^)())block {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
    MADDefer *defer =  [[MADDefer alloc] init];
    defer.block = block;
    return [defer autorelease];
}

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
    if (_block)
        _block();
    [super dealloc];
}

@end

void defer(void (^block)()) {
    static MADDefer *d;
    d = [MADDefer defer:block];
}
