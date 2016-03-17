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

- (BOOL)isExecuting {return self.state == executing; }

- (BOOL)isFinished { return self.state == finished || self.state == usercancelled || self.state == error || self.state == cancelled; }

/**
 Add a completion block to be executed after the `NSOperation` enters the
 "finished" state.
 */
-(void)addCompletionBlock:(void(^)(void))block {
    void(^existing)(void) = self.completionBlock;
    if (existing){
        /*
         If we already have a completion block, we construct a new one by
         chaining them together.
         */
        self.completionBlock = ^{
            existing();
            block();
        };
    } else {
        self.completionBlock = block;
    }
}

/// Add multiple depdendencies to the operation.
-(void)addDependencies:(NSArray /*NSOperation*/ *)dependencies {
    for (NSOperation * dependency in dependencies) {
        [self addDependency:dependency];
    }
}

#pragma mark - Convenience

- (bool)success { return self.state == finished; }

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
