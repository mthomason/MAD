//
//  MADApplication.m
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADApplication.h"
#import <UIKit/UIApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

@implementation MADApplication

static NSString * const MADApplicationIdMadDesigner                         = @"666001433";
static NSString * const MADApplicationIdMadViewer                           = @"666003759";

+ (MADAppDelegate)AppDelegate {
    id appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate;
}

+ (BOOL)isMADDesigner {
    MADAppDelegate appDelegate = [self AppDelegate];
    NSString *appIdentifier = [appDelegate applicationIdentifier];
    return [appIdentifier isEqualToString: MADApplicationIdMadDesigner];
}

+ (BOOL)isMADViewer {
    MADAppDelegate appDelegate = [self AppDelegate];
    NSString *appIdentifier = [appDelegate applicationIdentifier];
    return [appIdentifier isEqualToString: MADApplicationIdMadViewer];
}

@end
