//
//  MADTabBar.m
//  MAD
//
//  Created by Michael Thomason on 10/24/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTabBar.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADTabBar

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.tintColor = [MADColorEverydayApps newColorRed];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.tintColor = [MADColorEverydayApps newColorRed];
    }
    return self;
}

@end
