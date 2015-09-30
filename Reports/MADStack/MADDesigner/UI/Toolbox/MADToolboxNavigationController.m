//
//  MADToolboxNavigationController.m
//  MAD
//
//  Created by Michael Thomason on 11/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxNavigationController.h"

@interface MADToolboxNavigationController ()
    <UINavigationBarDelegate, UIBarPositioningDelegate>
@end

@implementation MADToolboxNavigationController

+ (void)initialize {
    [super initialize];
    if (self == [MADToolboxNavigationController self]) {
        [UINavigationBar appearanceWhenContainedIn:[MADToolboxNavigationController class], nil].barTintColor        = [UIColor clearColor];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
