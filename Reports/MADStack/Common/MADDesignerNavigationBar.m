//
//  MADDesignerNavigationBar.m
//  MAD Designer
//
//  Created by Michael on 2/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerNavigationBar.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADDesignerNavigationBar
/*
+ (void)initialize {
    [super initialize];
    if (self == [MADDesignerNavigationBar self]) {
        UIColor *c = [MADColorEverydayApps newColorBlue];
        [[MADDesignerNavigationBar appearance] setBarTintColor:c];
    }
}

- (UIBarStyle)barStyle {
    return UIBarStyleBlack;
}
*/
- (void)layoutSubviews {
	[super layoutSubviews];
	[self.topItem.titleView sizeToFit];
}

@end
