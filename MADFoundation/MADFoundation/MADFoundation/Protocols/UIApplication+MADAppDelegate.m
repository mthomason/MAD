//
//  UIApplication+MADAppDelegate.m
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIApplication+MADAppDelegate.h"
#import <MADApplicationProtocol.h>

NSString * const MADApplicationIdMadDesigner                         = @"666001433";
NSString * const MADApplicationIdMadViewer                           = @"666003759";

@implementation UIApplication (MADAppDelegate)

+ (MADAppDelegate)AppDelegate {
    MADAppDelegate appDelegate = (MADAppDelegate)[UIApplication sharedApplication].delegate;
    return appDelegate;
}

+ (BOOL)isMADDesigner {
    return [[[self AppDelegate] applicationIdentifier] isEqualToString: MADApplicationIdMadDesigner];
}

+ (BOOL)isMADViewer {
    return [[[self AppDelegate] applicationIdentifier] isEqualToString: MADApplicationIdMadViewer];
}

@end
