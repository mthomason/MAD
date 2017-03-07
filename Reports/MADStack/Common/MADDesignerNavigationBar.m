//
//  MADDesignerNavigationBar.m
//  MAD Designer
//
//  Created by Michael on 2/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerNavigationBar.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADDesignerNavigationBar

+ (void)initialize {
    [super initialize];
    if (self == [MADDesignerNavigationBar self]) {
        UIColor *c = [MADColorEverydayApps newColorBlue];
        [[MADDesignerNavigationBar appearance] setBarTintColor:c];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.topItem.titleView sizeToFit];
}

- (UIBarStyle)barStyle {
    return UIBarStyleBlack;
}

@end
