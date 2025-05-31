//
//  MADSettingsManager.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/17/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPreferencesManager.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSUbiquitousKeyValueStore.h>
#import <Foundation/NSNotification.h>
#import <dispatch/dispatch.h>

@interface MADPreferencesManager ()

	@property (nonatomic, strong) NSMutableSet *preferences;

@end

@implementation MADPreferencesManager

+ (instancetype)sharedManager {
	static id _sharedManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedManager = [[self alloc] initPrivate];
	});
	return _sharedManager;
}

- (void)dealloc {

}

- (instancetype)init {
	return [[self class] sharedManager];
}


- (instancetype)initPrivate {
	if (self = [super init]) {
		
		id preferences = [[NSMutableSet alloc] init];
		self.preferences = preferences;
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleNotificationKeyValueStoreDidChange:)
													 name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
												   object: nil];
		
		[[NSUbiquitousKeyValueStore defaultStore] synchronize];
	}
	return self;
}

- (void)addPreference:(MADPreference *)preference {
	if ([self.preferences containsObject:preference] != NSNotFound) {
		[self.preferences addObject:preference];
	}
}

#pragma mark - Notification Handlers

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {
	
	// One or more keys changed.
	NSNumber *changeReason;
	changeReason = notification.userInfo[NSUbiquitousKeyValueStoreChangeReasonKey];
	
	switch (changeReason.integerValue) {
		case NSUbiquitousKeyValueStoreServerChange:
			break;
		case NSUbiquitousKeyValueStoreInitialSyncChange:
			break;
		case NSUbiquitousKeyValueStoreQuotaViolationChange:
			break;
		case NSUbiquitousKeyValueStoreAccountChange:
			break;
			
		default:
			break;
	}
}

@end
