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
    NSURL *madDesignerEntitlementsUrl = [[NSBundle mainBundle] URLForResource:@"MAD Designer" withExtension:@"entitlements"];
    NSDictionary *madDesignerEntitlementsDictionary = [NSDictionary dictionaryWithContentsOfURL:madDesignerEntitlementsUrl];
    NSArray *madApplicationGroups = madDesignerEntitlementsDictionary[@"com.apple.security.application-groups"];
    return [madApplicationGroups firstObject];
}

+ (NSString *)ubiquityIdentifier {
    NSDictionary<NSString *,id> *madInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *ubiquitousContainers = madInfoDictionary[@"NSUbiquitousContainers"];
    NSArray<NSString *> *ubiquitousContainersKeys = [ubiquitousContainers allKeys];
    return [ubiquitousContainersKeys firstObject];
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
