//
//  MTNavigationControllerHideBottomBarUnlicensed.m
//  MAD
//
//  Created by Michael Thomason on 10/21/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTNavigationControllerHideBottomBarUnlicensed.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

@interface MTNavigationControllerHideBottomBarUnlicensed ()

@end

@implementation MTNavigationControllerHideBottomBarUnlicensed

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
            if (isLicensedUser == NO) {
                [self setToolbarHidden:YES];
                [self setHidesBottomBarWhenPushed:YES];
            }
        }];
    }
    return self;
}

@end
