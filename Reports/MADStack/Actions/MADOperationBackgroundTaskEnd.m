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
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Execute:", __PRETTY_FUNCTION__);

    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    NSArray<NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationBackgroundTaskProtocol)]) {
            backgroundTaskIdentifier = [(id <MADOperationBackgroundTaskProtocol>)dependency backgroundTaskIdentifier];
        }
    }
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish:", __PRETTY_FUNCTION__);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        [self finish];
    } else {
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish with error:", __PRETTY_FUNCTION__);
        NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:23 userInfo:nil];
        [self finishWithError:error];
    }

}

@end
