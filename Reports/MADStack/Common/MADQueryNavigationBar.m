//
//  MADQueryNavigationBar.m
//  MAD Designer
//
//  Created by Michael on 2/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryNavigationBar.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADQueryNavigationBar

+ (void)initialize {
    [super initialize];
    if (self == [MADQueryNavigationBar self]) {
        UIColor *c = [MADColorEverydayApps newColorBlue];
        [[MADQueryNavigationBar appearance] setBarTintColor:c];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
    }
    return self;
}

@end
