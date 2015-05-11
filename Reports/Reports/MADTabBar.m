//
//  MADTabBar.m
//  MAD
//
//  Created by Michael Thomason on 10/24/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBar.h"
#import "UIColor+EverydayApps.h"

@implementation MADTabBar

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
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
    self.tintColor = [UIColor tintColorRed];
}

@end
