//
//  MADOperationBackgroundTaskBegin.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationBackgroundTaskBegin.h"
#import <UIKit/UIApplication.h>
#import <os/log.h>

@interface MADOperationBackgroundTaskBegin ()

    @property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation MADOperationBackgroundTaskBegin

- (void)dealloc {
    ////os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    //os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    MADOperationBackgroundTaskBegin * __weak weakself = self;
    
    NSString *taskName = @"com.everdayapps.operation.document.create.begin";
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName: taskName
                                                                                 expirationHandler: ^{
        MADOperationBackgroundTaskBegin *sself = weakself;
        [[UIApplication sharedApplication] endBackgroundTask:sself.backgroundTaskIdentifier];
        sself.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];

    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [self finish];
    } else {
        NSString *domain = NSStringFromClass(self.class);
        NSError *error = [NSError errorWithDomain:domain code:22 userInfo:nil];
        [self finishWithError:error];
    }
    
}

@end
