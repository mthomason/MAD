//
//  MTNavigationControllerHideBottomBarUnlicensed.m
//  MAD
//
//  Created by Michael Thomason on 10/21/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTNavigationControllerHideBottomBarUnlicensed.h"
#import "MTStoreKitController.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

@interface MTNavigationControllerHideBottomBarUnlicensed ()

@end

@implementation MTNavigationControllerHideBottomBarUnlicensed

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser == NO) {
            self.toolbarHidden = YES;
            self.hidesBottomBarWhenPushed = YES;
        }
    }];
}

@end
