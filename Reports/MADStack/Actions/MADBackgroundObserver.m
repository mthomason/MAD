//
//  MADBackgroundObserver.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADBackgroundObserver.h"
#import <UIKit/UIApplication.h>

/**
 `BackgroundObserver` is an `OperationObserver` that will automatically begin
 and end a background task if the application transitions to the background.
 This would be useful if you had a vital `Operation` whose execution *must* complete,
 regardless of the activation state of the app. Some kinds network connections
 may fall in to this category, for example.
 */
@interface MADBackgroundObserver ()
    @property (nonatomic, assign) UIBackgroundTaskIdentifier identifier;
    @property (nonatomic, assign) BOOL isInBackground;
@end

@implementation MADBackgroundObserver

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]){
        // We need to know when the application moves to/from the background.
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(didEnterBackground:)
                                                     name: UIApplicationDidEnterBackgroundNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(didEnterForeground:)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        _isInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
        
        // If we're in the background already, immediately begin the background task.
        if (_isInBackground) {
            [self startBackgroundTask];
        }
    }
    return self;
}

- (void)didEnterBackground:(NSNotification *)notification {
    if (!_isInBackground) {
        self.isInBackground = YES;
        [self startBackgroundTask];
    }
}

- (void)didEnterForeground:(NSNotification *)notification {
    if (_isInBackground) {
        self.isInBackground = NO;
        [self endBackgroundTask];
    }
}

- (void)startBackgroundTask {
    if (self.identifier == UIBackgroundTaskInvalid) {
        self.identifier = [UIApplication.sharedApplication beginBackgroundTaskWithName: @"BackgroundObserver"
                                                                     expirationHandler: ^{
            [self endBackgroundTask];
        }];
    }
}

- (void)endBackgroundTask {
    if (self.identifier != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:_identifier];
        self.identifier = UIBackgroundTaskInvalid;
    }
}

#pragma mark - Operation Observer

- (void)operationDidStart:(MADOperation *)op { }
- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }
- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors { }

@end
