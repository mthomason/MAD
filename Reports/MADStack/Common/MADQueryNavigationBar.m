//
//  MADQueryNavigationBar.m
//  MAD Designer
//
//  Created by Michael on 2/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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

- (UIBarStyle)barStyle {
    return UIBarStyleBlack;
}

@end
