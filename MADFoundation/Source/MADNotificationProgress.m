//
//  MADNotificationProgress.m
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNotificationProgress.h"
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSOperation.h>
#import <math.h>
#import "MADProgress.h"

NSString * const MADNotificationProgressIdentifier = @"MADProgressNotification";
NSString * const MADNotificationProgressKey = @"p";

static inline double min_time_interval(void);
static inline double min_time_interval(void) {
	return 1.0 / 60.0;
}

@interface MADNotificationProgress ()
	@property (nonatomic, copy) NSDate *lastUpdate;
@end

@implementation MADNotificationProgress

static MADNotificationProgress *_sharedSingleton = nil;

- (void)dealloc {
	NSAssert(NO, @"Don't dealloc the singleton.");
}

+ (void)initialize {
	[super initialize];
	if (self == [MADNotificationProgress self]) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			_sharedSingleton = [[super allocWithZone:NULL] init];
			NSDate *lastUpdate = [NSDate date].copy;
			_sharedSingleton.lastUpdate = lastUpdate;
			[_sharedSingleton initializeProgressNotification];
		});
	}
}

+ (MADNotificationProgress *)sharedObject {
	return _sharedSingleton;
}

+ (instancetype)allocWithZone:(NSZone *)zone {
	return [self sharedObject];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (void)initializeProgressNotification { }

- (void)updateProgressOfObject:(id)object withMessage:(NSString *)message progress:(float)progress {
	if (fabs(self.lastUpdate.timeIntervalSinceNow) > min_time_interval()) {
		self.lastUpdate = [NSDate date];
		id madProgress = [[MADProgress alloc] initWithMessage:message andProgress:progress];
		id userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:madProgress, MADNotificationProgressKey, nil];
		NSNotification *notification = [NSNotification notificationWithName: MADNotificationProgressIdentifier
																	 object: object
																   userInfo: userInfo];
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	}
}

- (void)updateProgressWithMessage:(NSString *)message progress:(float)progress {
	if (fabs(self.lastUpdate.timeIntervalSinceNow) > min_time_interval()) {
		self.lastUpdate = [NSDate date];
		MADProgress *madProgress = [[MADProgress alloc] initWithMessage:message andProgress:progress];
		[[NSOperationQueue mainQueue] addOperationWithBlock: ^{
			NSNotification *notification = [NSNotification notificationWithName: MADNotificationProgressIdentifier
																		 object: madProgress
																	   userInfo: nil];
			[[NSNotificationCenter defaultCenter] postNotification:notification];
		}];
	}
}

- (void)updateProgress:(MADProgress *)progress {
	if (fabs(self.lastUpdate.timeIntervalSinceNow) > min_time_interval()) {
		NSDate *lastUpdate = [NSDate date].copy;
		self.lastUpdate = lastUpdate;
		[[NSOperationQueue mainQueue] addOperationWithBlock: ^{
			NSNotification *notification = [NSNotification notificationWithName: MADNotificationProgressIdentifier
																		 object: progress
																	   userInfo: nil];
			[[NSNotificationCenter defaultCenter] postNotification:notification];
		}];
	}
}

@end
