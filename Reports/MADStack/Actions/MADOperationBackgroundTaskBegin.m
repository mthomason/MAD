//
//  MADOperationBackgroundTaskBegin.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationBackgroundTaskBegin.h"
#import <UIKit/UIApplication.h>

@interface MADOperationBackgroundTaskBegin ()

    @property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation MADOperationBackgroundTaskBegin

- (instancetype)initWithKey:(NSString *)key withDescription:(NSString *)description {
    if (self = [super init]) {

    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

     self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [self finish];
    } else {
        NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:22 userInfo:nil];
        [self finishWithError:error];
    }
    
}

@end
