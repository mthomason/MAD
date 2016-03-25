//
//  MADNotificationProgress.m
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADNotificationProgress.h"
#import "MADProgress.h"
#import <dispatch/once.h>

NSString * const MADNotificationProgressIdentifier = @"MADProgressNotification";

@interface MADNotificationProgress ()
    @property (nonatomic, copy) NSDate *lastUpdate;
@end

@implementation MADNotificationProgress

    static MADNotificationProgress *sharedSingleton = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        sharedSingleton.lastUpdate = [NSDate date];
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

- (void)initalizeProgressNotification {

}

- (void)updateProgress:(MADProgress *)progress {
    if (self.lastUpdate.timeIntervalSinceNow > 1/60) {
        self.lastUpdate = [NSDate date];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            NSNotification *notification = [NSNotification notificationWithName: MADNotificationProgressIdentifier
                                                                         object: progress
                                                                       userInfo: nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }];
    }
}

@end
