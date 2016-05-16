//
//  MADTransparentPresentationController.m
//  MAD
//
//  Created by Michael Thomason on 10/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTransparentPresentationController.h"
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@implementation MADTransparentPresentationController

+ (void)initialize {
    [super initialize];
    if (self == [MADTransparentPresentationController self]) {
        [UINavigationBar appearanceWhenContainedIn:[MADTransparentPresentationController class], nil].barTintColor  = [UIColor clearColor];
    }
}

- (BOOL) shouldRemovePresentersView {
    return NO;
}

- (void)presentationTransitionWillBegin { }

@end
