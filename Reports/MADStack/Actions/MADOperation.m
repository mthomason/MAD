//
//  MADOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperation.h"
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSException.h>
#import "MADOperationCondition.h"
#import "MADOperationConditionResult.h"
#import "MADOperationObserver.h"

static NSString * const MADOperatorSelectorIsReady      = @"isReady";
static NSString * const MADOperatorSelectorIsExecuting  = @"isExecuting";
static NSString * const MADOperatorSelectorIsFinished   = @"isFinished";
static NSString * const MADOperatorSelectorState        = @"state";

@interface MADOperation() {
    MADOperationState _state;
}

    @property (nonatomic, strong) NSMutableArray *internalErrors;
    @property (nonatomic, assign) bool hasFinishedAlready;

@end

@implementation MADOperation

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (void)dealloc { }

#pragma mark - Lazy Load

- (NSMutableArray *)internalErrors {
    return (_internalErrors == nil) ? _internalErrors = [[NSMutableArray alloc] init] : _internalErrors;
}

- (NSMutableArray <__kindof NSObject <MADOperationCondition> *> *)conditions {
    return (_conditions == nil) ? _conditions = [[NSMutableArray alloc] init] : _conditions;
}

- (NSMutableArray <__kindof NSObject <MADOperationObserver> *> *)observers {
    return (_observers == nil) ? _observers = [[NSMutableArray alloc] init] : _observers;
}

#pragma mark - KVO

// use the KVO mechanism to indicate that changes to "state" affect other properties as well
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSArray *keys = [[NSArray alloc] initWithObjects:MADOperatorSelectorIsReady, MADOperatorSelectorIsExecuting, MADOperatorSelectorIsFinished, nil];
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

- (void)willEnqueue { self.state = pending; }

- (void)setState:(MADOperationState)newState {
    // Manually fire the KVO notifications for state change, since this is "private".
    [self willChangeValueForKey:MADOperatorSelectorState];
    
    @synchronized(self) {
            
        if (_state == finished) {
            return;
        }
        NSAssert([self canTransitionToState:newState], @"Performing invalid state transition.");
        _state = newState;
    }
    
    [self didChangeValueForKey:MADOperatorSelectorState];
}

- (BOOL)isReady {
    switch (self.state) {

        case initialized:
            // If the operation has been cancelled, "isReady" should return true
            return self.cancelled;

        case pending:
            if (self.cancelled) {                                   // If the operation has been cancelled, "isReady" should return true
                return YES;
            } else {

                if (super.ready) { [self evaluateConditions]; }     // If super isReady, conditions can be evaluated
                return NO;                                          // Until conditions have been evaluated, "isReady" returns false
            }

        case ready:
            return super.ready || self.cancelled;
        
        default:
            return NO;
    }
}

- (BOOL)isExecuting {return self.state == executing; }

- (BOOL)isFinished { return self.state == finished; }


- (BOOL)userInitiated { return self.qualityOfService == NSQualityOfServiceUserInitiated; }

- (void)setUserInitiated:(BOOL)newValue {
    NSAssert(self.state < executing, @"Cannot modify userInitiated after execution has begun.");
    self.qualityOfService = newValue ? NSQualityOfServiceUserInitiated : NSQualityOfServiceDefault;
}

- (bool)canTransitionToState:(MADOperationState)target {
    return (target == pending               && self.state == initialized)
        || (target == evaluatingConditions  && self.state == pending)
        || (target == ready                 && self.state == evaluatingConditions)
        || (target == executing             && self.state == ready)
        || (target == finishing             && self.state == ready)
        || (target == finishing             && self.state == executing)
        || (target == finished              && self.state == finishing);
}

- (void)evaluateConditions {
    NSAssert(self.state == pending && !self.cancelled, @"evaluateConditions() was called out-of-order");
    
    self.state = evaluatingConditions;
    
    [MADOperationConditionResult evaluateConditions:self.conditions operation:self completion:^(NSArray * failures) {
        [self.internalErrors addObjectsFromArray:failures];
        self.state = ready;
    }];
}

#pragma mark - Conditions

- (void)addCondition:(NSObject <MADOperationCondition> *)condition {
    NSAssert(self.state < evaluatingConditions, @"Cannot modify observers after execution has begun.");
    [self.conditions addObject:condition];
}

- (void)addDependency:(NSOperation *)op {
    NSAssert(self.state < executing, @"Dependencies cannot be modified after execution has begun.");
    [super addDependency:op];
}

#pragma mark - Observers

- (void)addObserver:(NSObject <MADOperationObserver> *)observer {
    NSAssert(self.state < executing, @"Cannot modify observers after execution has begun.");
    [self.observers addObject:observer];
}

#pragma mark - Execution and Cancellation
- (void)start {
    
    // NSOperation.start() contains important logic that shouldn't be bypassed.
    [super start];
    
    // If the operation has been cancelled, we still need to enter the "Finished" state.
    if (self.cancelled) {
        [self finish];
    }
}

- (void)main {
    NSAssert(self.state == ready, @"This operation must be performed on an operation queue.");
    
    if (!self.cancelled && self.internalErrors.count == 0) {

        self.state = executing;

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

- (void)cancel {
    [self cancelWithError:nil];
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

#pragma mark - Finishing

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
        NSArray *errorArray = [[NSArray alloc] initWithObjects:error, nil];
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
    if (!self.hasFinishedAlready) {
        self.hasFinishedAlready = YES;
        self.state = finishing;
        
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
        
        self.state = finished;
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
    //NSAssert(NO, @"Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.");
}

@end
