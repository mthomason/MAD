//
//  UIApplication+MADApplicationProtocol.m
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADAppDelegate.h"
#import <MADApplicationProtocol.h>

@implementation UIApplication (MADAppDelegate)

+ (MADAppDelegate)AppDelegate {
    MADAppDelegate appDelegate = (MADAppDelegate)[UIApplication sharedApplication].delegate;
    return appDelegate;
}

@end
