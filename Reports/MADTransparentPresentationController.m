//
//  MADTransparentPresentationController.m
//  MAD
//
//  Created by Michael Thomason on 10/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTransparentPresentationController.h"

@implementation MADTransparentPresentationController



- (BOOL) shouldRemovePresentersView {
    return NO;
}

- (void)presentationTransitionWillBegin {
    for (UIView *v in self.containerView.subviews) {
        NSLog(@"%@", v);
        for (UIView *va in v.subviews) {
            NSLog(@"%@", va);
        }
    }
}

@end
