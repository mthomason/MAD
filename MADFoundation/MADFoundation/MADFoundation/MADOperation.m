//
//  MADOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <MADFoundation/MADOperation.h>
#import <os/log.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADOperationObserver.h>
#import "MADBlockObserver.h"

static NSString * const MADOperatorSelectorIsReady      = @"isReady";
static NSString * const MADOperatorSelectorIsExecuting  = @"isExecuting";
static NSString * const MADOperatorSelectorIsFinished   = @"isFinished";
static NSString * const MADOperatorSelectorState        = @"state";

@interface MADOperation()
    @property (nonatomic, strong) NSMutableArray *internalErrors;
    @property (atomic, assign) BOOL hasFinishedAlready;
@end

@implementation MADOperation {
    MADOperationState _state;
}

#pragma mark -
#pragma mark Static functions

- (void)dealloc { }

- (instancetype)init {
    if (self = [super init]) {
        _hasFinishedAlready = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Lazy Load

- (NSMutableArray *)internalErrors {
    return (_internalErrors == nil) ?
        _internalErrors = [[NSMutableArray alloc] init] : _internalErrors;
}

- (MADMutableOperationConditions *)conditions {
    return (_conditions == nil) ? _conditions = [[NSMutableArray alloc] init] : _conditions;
}

- (MADMutableOperationObservers *)observers {
    return (_observers == nil) ? _observers = [[NSMutableArray alloc] init] : _observers;
}

#pragma mark -
#pragma mark KVO

// use the KVO mechanism to indicate that changes to "state" affect other properties as well
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSArray *keys = [[NSArray alloc] initWithObjects: MADOperatorSelectorIsReady,
                                                      MADOperatorSelectorIsExecuting,
                                                      MADOperatorSelectorIsFinished, nil];
    if ([keys containsObject:key]) {
        NSSet *result = [[NSSet alloc] initWithObjects:MADOperatorSelectorState, nil];
        return result;
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}

- (MADOperationState)state {
    @synchronized(self) {
        return _state;
    }
}

- (void)willEnqueue { self.state = MADOperationStatePending; }

- (void)setState:(MADOperationState)newState {
    os_log_info(OS_LOG_DEFAULT, "%s is %s", NSStringFromClass(self.class).UTF8String, MADStringOperationState(newState));

    // Manually fire the KVO notifications for state change, since this is "private".
    [self willChangeValueForKey:MADOperatorSelectorState];
    
    @synchronized(self) {
            
        if (_state == MADOperationStateFinished) {
            return;
        }
        NSAssert([self canTransitionToState:newState], @"Performing invalid state transition.");
        _state = newState;
    }
    
    [self didChangeValueForKey:MADOperatorSelectorState];
}

- (BOOL)isReady {
    switch (self.state) {

        case MADOperationStateInitialized:
            // If the operation has been cancelled, "isReady" should return YES
            return self.cancelled;

        case MADOperationStatePending:
            if (self.cancelled) {
                self.state = MADOperationStateReady;
                return YES;
            }
            if (super.ready) {
                [self evaluateConditions];
                return self.state == MADOperationStateReady;
            }
            
        case MADOperationStateReady:
            return super.ready || self.cancelled;
        
        default:
            return NO;
    }
}

- (BOOL)isExecuting {return self.state == MADOperationStateExecuting; }

- (BOOL)isFinished { return self.state == MADOperationStateFinished; }


- (BOOL)userInitiated { return self.qualityOfService == NSQualityOfServiceUserInitiated; }

- (void)setUserInitiated:(BOOL)newValue {
    NSAssert(self.state < MADOperationStateExecuting, @"Cannot modify userInitiated after execution has begun.");
    self.qualityOfService = newValue ? NSQualityOfServiceUserInitiated : NSQualityOfServiceDefault;
}

- (BOOL)canTransitionToState:(MADOperationState)target {
    return (target == MADOperationStatePending               && self.state == MADOperationStateInitialized)
        || (target == MADOperationStateEvaluatingConditions  && self.state == MADOperationStatePending)
        || (target == MADOperationStateReady                 && self.state == MADOperationStatePending              && self.isCancelled)
        || (target == MADOperationStateFinished              && self.state == MADOperationStatePending              && self.isCancelled)
        || (target == MADOperationStateReady                 && self.state == MADOperationStateEvaluatingConditions)
        || (target == MADOperationStateExecuting             && self.state == MADOperationStateReady)
        || (target == MADOperationStateFinishing             && self.state == MADOperationStateReady)
        || (target == MADOperationStateFinishing             && self.state == MADOperationStateExecuting)
        || (target == MADOperationStateFinished              && self.state == MADOperationStateFinishing);
}

- (void)evaluateConditions {
    NSAssert(self.state == MADOperationStatePending && !self.cancelled,
             @"evaluateConditions() was called out-of-order");
    
    self.state = MADOperationStateEvaluatingConditions;
    
    MADOperation __weak *weakself = self;
    [MADOperationConditionResult evaluateConditions: self.conditions
                                          operation: self
                                         completion: ^(NSArray * failures) {
        MADOperation *sself = weakself;
        if (sself) {
            [sself.internalErrors addObjectsFromArray:failures];
            sself.state = MADOperationStateReady;
        }
    }];
}

#pragma mark -
#pragma mark Conditions

- (void)addCondition:(NSObject <MADOperationCondition> *)condition {
    NSAssert(self.state < MADOperationStateEvaluatingConditions, @"Cannot modify observers after execution has begun.");
    [self.conditions addObject:condition];
}

- (void)addDependency:(NSOperation *)op {
    NSAssert(self.state < MADOperationStateExecuting, @"Dependencies cannot be modified after execution has begun.");
    [super addDependency:op];
}

#pragma mark -
#pragma mark Observers

- (void)addObserver:(NSObject <MADOperationObserver> *)observer {
    NSAssert(self.state < MADOperationStateExecuting, @"Cannot modify observers after execution has begun.");
    [self.observers addObject:observer];
}

#pragma mark -
#pragma mark Execution and Cancellation
- (void)start {
    
    if (self.isReady) {
        [self main];
        
    } else if (self.cancelled) {
        [self finish];
    }
}

- (void)main {
    NSAssert(self.state == MADOperationStateReady, @"This operation must be performed on an operation queue.");
    
    if (!self.cancelled && self.internalErrors.count == 0) {

        self.state = MADOperationStateExecuting;

        NSArray *observers = self.observers;
        for (NSObject <MADOperationObserver> *observer in observers) {
            [observer operationDidStart:self];
        }

        [self execute];

    } else {
        [self finish];
    }
}

    /**
     `execute()` is the entry point of execution for all `Operation` subclasses.
        If you subclass `Operation` and wish to customize its execution, you would
        do so by overriding the `execute()` method.
 
        At some point, your `Operation` subclass must call one of the "finish"
        methods defined below; this is how you indicate that your operation has
        finished its execution, and that operations dependent on yours can re-evaluate
        their readiness state.
     */
- (void)execute {
    [self finish];
}

- (void)cancelWithError:(NSError *)error {
    if (error) {
        [self.internalErrors addObject:error];
    }
    [self cancel];
}

- (void)produceOperation:(NSOperation *)operation {
    for (NSObject <MADOperationObserver> *observer in self.observers) {
        [observer operation:self didProduceOperation:operation];
    }
}

#pragma mark -
#pragma mark Finishing

    /**
    Most operations may finish with a single error, if they have one at all.
        This is a convenience method to simplify calling the actual `finish()`
        method. This is also useful if you wish to finish with an error provided
        by the system frameworks. As an example, see `DownloadEarthquakesOperation`
        for how an error from an `NSURLSession` is passed along via the
        `finishWithError()` method.
    */
- (void)finish {
    [self finish:nil];
}

- (void)finishWithError:(NSError *)error {
    if (error) {
        NSError *errorCopy = error.copy;
        NSArray *errorArray = [[NSArray alloc] initWithObjects:errorCopy, nil ];
        [self finish:errorArray];
    } else {
        [self finish:nil];
    }
}

    /**
        A private property to ensure we only notify the observers once that the
        operation has finished.
     */
- (void)finish:(NSArray *)errors {
    //os_log_info(OS_LOG_DEFAULT, "Finish %s", NSStringFromClass(super.class).UTF8String);
    if (!self.hasFinishedAlready) {
        self.hasFinishedAlready = YES;
        self.state = MADOperationStateFinishing;
        
        NSArray *combinedErrors;
        if (errors) {
            NSArray *combined = [self.internalErrors arrayByAddingObjectsFromArray:errors];
            combinedErrors = combined.copy;
        } else {
            combinedErrors = self.internalErrors.copy;
        }
        [self finished:combinedErrors];
        
        
        NSArray *observers = self.observers;
        for (NSObject <MADOperationObserver> *observer in observers) {
            [observer operationDidFinish:self errors:combinedErrors];
        }
        
        self.state = MADOperationStateFinished;

    }
}

    /**
     Subclasses may override `finished(_:)` if they wish to react to the operation
        finishing with errors. For example, the `LoadModelOperation` implements
        this method to potentially inform the user about an error when trying to
        bring up the Core Data stack.
     */
- (void)finished:(NSArray *)errors {
    // No op.
}

- (void)waitUntilFinished {
    [super waitUntilFinished];
    /*
    Waiting on operations is almost NEVER the right thing to do. It is
        usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
        or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
        use waiting when they should instead be chaining discrete operations
        together using dependencies.
     
     To reinforce this idea, invoking `waitUntilFinished()` will crash your
        app, as incentive for you to find a more appropriate way to express
        the behavior you're wishing to create.
     */
    //NSAssert(NO, @"Waiting on operations is an anti-pattern. Remove this
        // ONLY if you're absolutely sure there is No Other Way™.");
}

- (void)cleanup {
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        [self removeDependency:dependency];
    }
    
    [self.conditions removeAllObjects];
    [self.observers removeAllObjects];
    
}

@end
