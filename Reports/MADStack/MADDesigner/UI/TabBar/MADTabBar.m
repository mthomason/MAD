//
//  MADTabBar.m
//  MAD
//
//  Created by Michael Thomason on 10/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBar.h"

@implementation MADTabBar

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.tintColor = [MADColor tintColorRed];
}

@end
