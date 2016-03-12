//
//  MADOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperation.h"
#import <Foundation/NSKeyValueObserving.h>

@interface MADOperation()

    @property (nonatomic, assign, readwrite) MADOperationState state;

@end

@implementation MADOperation

- (BOOL)isReady { return self.state == ready; }

- (BOOL)isExecuting {return self.state == executing; }

- (BOOL)isFinished { return self.state == finished || self.state == error || self.state == cancelled; }

#pragma mark - Convenience

- (bool)success { return self.state == finished; }

- (void)setStateReady {
    self.state = ready;
}

- (void)setStateCanceled {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = cancelled;
    [self didChangeValueForKey:isFinished];
}

- (void)setStateError {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = error;
    [self didChangeValueForKey:isFinished];
}

- (void)setStateFinished {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = finished;
    [self didChangeValueForKey:isFinished];
}

- (void)setStateExecuting {
    NSString *isExecuting = NSStringFromSelector(@selector(isExecuting));
    [self willChangeValueForKey:isExecuting];
    self.state = executing;
    [self didChangeValueForKey:isExecuting];
}

- (void)setStateUserCancelled {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = usercancelled;
    [self didChangeValueForKey:isFinished];
}

@end
