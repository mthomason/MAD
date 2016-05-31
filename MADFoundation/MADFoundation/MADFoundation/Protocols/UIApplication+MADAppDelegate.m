//
//  UIApplication+MADAppDelegate.m
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIApplication+MADAppDelegate.h"
#import <UIKit/UIApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

NSString * const MADApplicationIdMadDesigner                         = @"666001433";
NSString * const MADApplicationIdMadViewer                           = @"666003759";

@implementation MADApplication

+ (MADAppDelegate)AppDelegate {
    id appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate;
}

+ (BOOL)isMADDesigner {
    MADAppDelegate __weak appDelegate = [self AppDelegate];
    NSString *appIdentifier = [appDelegate applicationIdentifier];
    return [appIdentifier isEqualToString: MADApplicationIdMadDesigner];
}

+ (BOOL)isMADViewer {
    MADAppDelegate __weak appDelegate = [self AppDelegate];
    NSString *appIdentifier = [appDelegate applicationIdentifier];
    return [appIdentifier isEqualToString: MADApplicationIdMadViewer];
}

@end
