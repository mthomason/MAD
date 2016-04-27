//
//  MADNotificationProgress.m
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADNotificationProgress.h"
#import "MADProgress.h"
#import <Foundation/NSNotification.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <dispatch/once.h>
#import <math.h>

NSString * const MADNotificationProgressIdentifier = @"MADProgressNotification";
NSString * const MADNotificationProgressKey = @"p";

@interface MADNotificationProgress ()
    @property (nonatomic, copy) NSDate *lastUpdate;
@end

@implementation MADNotificationProgress

static MADNotificationProgress *sharedSingleton = nil;

- (void)dealloc {
    NSAssert(NO, @"Don't dealloc the singleton.");
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        NSDate *lastUpdate = [NSDate date].copy;
        sharedSingleton.lastUpdate = lastUpdate;
        [sharedSingleton initalizeProgressNotification];
    });
}

+ (MADNotificationProgress *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)initalizeProgressNotification { }

- (void)updateProgressOfObject:(id)object withMessage:(NSString *)message progress:(float)progress {
    if (fabs(self.lastUpdate.timeIntervalSinceNow) > 1.0/60.0) {
        self.lastUpdate = [NSDate date];
        MADProgress *madProgress = [[MADProgress alloc] initWithMessage:message andProgress:progress];
        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:madProgress, MADNotificationProgressKey, nil];
        NSNotification *notification = [NSNotification notificationWithName: MADNotificationProgressIdentifier object:
        object  userInfo: userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (void)updateProgressWithMessage:(NSString *)message progress:(float)progress {
    if (fabs(self.lastUpdate.timeIntervalSinceNow) > 1.0/60.0) {
        self.lastUpdate = [NSDate date];
        MADProgress *madProgress = [[MADProgress alloc] initWithMessage:message andProgress:progress];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            NSNotification *notification = [NSNotification notificationWithName: MADNotificationProgressIdentifier object: madProgress userInfo: nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }];
    }
}

- (void)updateProgress:(MADProgress *)progress {
    if (fabs(self.lastUpdate.timeIntervalSinceNow) > 1.0/60.0) {
        NSDate *lastUpdate = [NSDate date].copy;
        self.lastUpdate = lastUpdate;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            NSNotification *notification = [NSNotification notificationWithName: MADNotificationProgressIdentifier object: progress userInfo: nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }];
    }
}

@end
