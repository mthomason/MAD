//
//  UIApplication+Extras.m
//  MAD
//
//  Created by Michael Thomason on 9/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "UIApplication+Extras.h"
#import "MADAppConfiguration.h"

@implementation UIApplication (Extras)

+ (NSString *)version {
    static NSString *version;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        version = infoDict[@"CFBundleVersion"];
    });
    return version;
}

- (void)setNetworkActivityIndicatorVisibleThreadSafe:(BOOL)networkActivityIndicatorVisible {
    static NSInteger setVisibleCounter = 0;
    if (networkActivityIndicatorVisible)
        setVisibleCounter++;
    else
        setVisibleCounter--;
    
    if (setVisibleCounter == 0) {
        networkActivityIndicatorVisible = NO;
    }
    if ([NSThread isMainThread] == NO) {
        __weak UIApplication *weakself = self;
        if (weakself.isNetworkActivityIndicatorVisible != networkActivityIndicatorVisible) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [weakself setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
            });
        }
    } else {
        if (self.isNetworkActivityIndicatorVisible != networkActivityIndicatorVisible) {
            [self setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
        }
    }
}

- (UIBackgroundTaskIdentifier)requestBackgroundTask {
    __block UIBackgroundTaskIdentifier bgTask = [self beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    return bgTask;
}

- (void)handoffBackground:(NSNumber *)bgTask {
    [self endBackgroundTask:bgTask.unsignedIntegerValue];
}

- (void)handoffBackgroundUsingTimer:(NSNumber *)bgTask {
    
    NSTimeInterval time = self.backgroundTimeRemaining > 7.0 ? 5.0 : self.backgroundTimeRemaining - 0.1;
    [NSTimer scheduledTimerWithTimeInterval: time
                                     target: self
                                   selector: @selector(handoffBackground:)
                                   userInfo: bgTask
                                    repeats: NO];
    
}

@end
