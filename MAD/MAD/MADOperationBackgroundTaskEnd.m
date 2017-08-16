//
//  MADOperationBackgroundTaskEnd.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationBackgroundTaskEnd.h"
#import "MADOperationBackgroundTaskBegin.h"
#import <os/log.h>

@interface MADOperationBackgroundTaskEnd ()

@end

@implementation MADOperationBackgroundTaskEnd

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    NSArray<NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationBackgroundTaskProtocol)]) {
            backgroundTaskIdentifier = [(id <MADOperationBackgroundTaskProtocol>)dependency backgroundTaskIdentifier];
        }
    }
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        [self finish];
    } else {
        NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:23 userInfo:nil];
        [self finishWithError:error];
    }

}

@end
