//
//  MADApplication.m
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADApplication.h"

#if TARGET_OS_MACCATALYST || TARGET_OS_IOS
#import <UIKit/UIApplication.h>
#elif TARGET_OS_OSX
#import <AppKit/NSApplication.h>
#endif

#import <Foundation/NSThread.h>
#import <MADFoundation/MADApplicationProtocol.h>

@implementation MADApplication

static NSString * const MADApplicationIdMadDesigner                         = @"666001433";
static NSString * const MADApplicationIdMadViewer                           = @"666003759";

+ (id <UIApplicationDelegate, MADApplicationProtocol>)AppDelegate {
	id appDelegate;
	if ([NSThread isMainThread]) {
		#if TARGET_OS_MACCATALYST || TARGET_OS_IOS
		appDelegate = [UIApplication sharedApplication].delegate;
		#elif TARGET_OS_OSX
		appDelegate = [NSApplication sharedApplication].delegate;
		#else
		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:@"Unsupported platform."
									 userInfo:nil];
		#endif
	} else {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:@"Only call on main thread."
									 userInfo:nil];
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
	id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [self AppDelegate];
	NSString *appIdentifier = [appDelegate applicationIdentifier];
	return [appIdentifier isEqualToString: MADApplicationIdMadDesigner];
}

+ (BOOL)isMADViewer {
	id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [self AppDelegate];
	NSString *appIdentifier = [appDelegate applicationIdentifier];
	return [appIdentifier isEqualToString: MADApplicationIdMadViewer];
}

@end
