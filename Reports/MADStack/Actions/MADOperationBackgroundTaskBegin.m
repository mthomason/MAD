//
//  MADOperationBackgroundTaskBegin.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationBackgroundTaskBegin.h"
#import <UIKit/UIApplication.h>
#import <os/log.h>

@interface MADOperationBackgroundTaskBegin ()

    @property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation MADOperationBackgroundTaskBegin

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);

    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    MADOperationBackgroundTaskBegin * __weak weakself = self;
    
    UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        MADOperationBackgroundTaskBegin *sself = weakself;
        [[UIApplication sharedApplication] endBackgroundTask:sself.backgroundTaskIdentifier];
        sself.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];

    self.backgroundTaskIdentifier = identifier;
    
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [self finish];
    } else {
        NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:22 userInfo:nil];
        [self finishWithError:error];
    }
    
}

@end
