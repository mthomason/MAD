//
//  MADViewerNavigationBar.m
//  MAD Designer
//
//  Created by Michael on 2/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADViewerNavigationBar.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADViewerNavigationBar

+ (void)initialize {
    [super initialize];
    if (self == [MADViewerNavigationBar self]) {
        UIColor *c = [MADColorEverydayApps newColorBlue];
        [[MADViewerNavigationBar appearance] setBarTintColor:c];
    }
}

- (UIBarStyle)barStyle {
    return UIBarStyleBlack;
}

@end
