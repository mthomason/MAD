//
//  MADApplication.m
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADApplication.h"
#import <UIKit/UIApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

@implementation MADApplication

static NSString * const MADApplicationIdMadDesigner                         = @"666001433";
static NSString * const MADApplicationIdMadViewer                           = @"666003759";

+ (MADAppDelegate)AppDelegate {
    id appDelegate;
    if ([NSThread isMainThread]) {
        appDelegate = [UIApplication sharedApplication].delegate;
    } else {
        @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                       reason: @"Only call on main thread."
                                     userInfo: nil];
    }
    return appDelegate;
}

+ (NSString *)groupIdentifier {
    __block NSString *groupIdentifier = nil;
    if ([NSThread isMainThread]) {
        id <MADApplicationProtocol> appDelegate;
        appDelegate = (id <MADApplicationProtocol>)[UIApplication sharedApplication].delegate;
        groupIdentifier = [appDelegate groupIdentifier];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            id <MADApplicationProtocol> appDelegate;
            appDelegate = (id <MADApplicationProtocol>)[UIApplication sharedApplication].delegate;
            groupIdentifier = [appDelegate groupIdentifier];
        });
    }
    return groupIdentifier;
}

+ (NSString *)ubiquityIdentifier {
    __block NSString *ubiquityIdentifier = nil;
    if ([NSThread isMainThread]) {
        id <MADApplicationProtocol> appDelegate;
        appDelegate = (id <MADApplicationProtocol>)[UIApplication sharedApplication].delegate;
        ubiquityIdentifier = [appDelegate ubiquityIdentifier];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            id <MADApplicationProtocol> appDelegate;
            appDelegate = (id <MADApplicationProtocol>)[UIApplication sharedApplication].delegate;
            ubiquityIdentifier = [appDelegate ubiquityIdentifier];
        });
    }
    return ubiquityIdentifier;
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
