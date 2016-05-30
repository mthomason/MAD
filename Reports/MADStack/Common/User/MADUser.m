//
//  MADUser.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/22/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADUser.h"

#import <Foundation/NSUUID.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSUbiquitousKeyValueStore.h>
#import <Foundation/NSUserDefaults.h>
#import <dispatch/dispatch.h>
#import "MADPreference.h"

static const char *     MADIDQueueUserPreferences = "preferences.everydayapps.mad.ubiquitout";
static NSString * const MADAppConfigurationApplicationGroupsPrimary =
                                                                @"group.everydayapps.mad.primary";
static NSString * const MADIDUser                                   = @"MADIDUser";

@interface MADUser () {
    BOOL _isFirstLaunchSet;
    CFUUIDRef _uuid;
}

@property (nonatomic, strong) dispatch_queue_t queue_user_preferences;

@end

@implementation MADUser

- (instancetype)init {
    if (self = [super init]) {
        SEL handler;
        handler = @selector(handleNotificationKeyValueStoreDidChange:);
        NSString *name;
        name = NSUbiquitousKeyValueStoreDidChangeExternallyNotification;
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: handler
                                                     name: name
                                                   object: nil];

    }
    return self;
}

- (dispatch_queue_t)queue_user_preferences {
    return !_queue_user_preferences ?
    (_queue_user_preferences = dispatch_queue_create(MADIDQueueUserPreferences,
                                                     DISPATCH_QUEUE_SERIAL)) :
    _queue_user_preferences;
}

- (BOOL)isFirstTimeEver {
    if (_isFirstLaunchSet) return NO;
    
    BOOL firstLaunch;
    if ((firstLaunch = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:MADIDUser] == nil)) {
        dispatch_async(self.queue_user_preferences, ^{
            NSUUID *uuid = [NSUUID UUID];
            [[NSUbiquitousKeyValueStore defaultStore] setObject:uuid.UUIDString forKey:MADIDUser];
            [[NSUbiquitousKeyValueStore defaultStore] synchronize];
        });
        return YES;
    } else {
        return NO;
    }
    return NO;
}

- (void)uuid {
    
    NSUserDefaults *defaults;
    defaults = [[NSUserDefaults alloc] initWithSuiteName:MADAppConfigurationApplicationGroupsPrimary];
    //self.applicationUserDefaults = defaults;
}

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {
    NSNumber * __unsafe_unretained changeReason;
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
