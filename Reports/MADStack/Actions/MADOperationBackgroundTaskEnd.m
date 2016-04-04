//
//  MADOperationBackgroundTaskEnd.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationBackgroundTaskEnd.h"
#import "MADOperationBackgroundTaskBegin.h"
#import <UIKit/UIApplication.h>

@interface MADOperationBackgroundTaskEnd ()

@end

@implementation MADOperationBackgroundTaskEnd

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    NSArray<NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADBackgroundTaskProtocol)]) {
            backgroundTaskIdentifier = [(id <MADBackgroundTaskProtocol>)dependency backgroundTaskIdentifier];
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
