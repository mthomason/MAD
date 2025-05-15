//
//  MADOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import <MADFoundation/MADOperation.h>
#import <os/log.h>
#import <pthread.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADOperationObserver.h>
#import "MADBlockObserver.h"
#import "madlog.h"

static NSString * const MADOperatorSelectorIsReady      = @"isReady";
static NSString * const MADOperatorSelectorIsExecuting  = @"isExecuting";
static NSString * const MADOperatorSelectorIsFinished   = @"isFinished";
static NSString * const MADOperatorSelectorState        = @"state";

@interface MADOperation()
	@property (nonatomic, strong) NSMutableArray *internalErrors;
	@property (atomic, assign) BOOL hasFinishedAlready;
	//@property (nonatomic, assign) MADOperationState state; // Backing ivar for state
@end

@implementation MADOperation {
	MADOperationState _state;
	pthread_mutex_t _stateLock;
}

#pragma mark -
#pragma mark Static functions

- (void)dealloc {
	// Clean up the mutex
	pthread_mutex_destroy(&_stateLock);
}

- (instancetype)init {
	if (self = [super init]) {
		_state = MADOperationStateInitialized;
		
		// Initialize the recursive mutex
		pthread_mutexattr_t attr;
		pthread_mutexattr_init(&attr);
		pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&_stateLock, &attr);
		pthread_mutexattr_destroy(&attr);
		
		_hasFinishedAlready = NO;
	}
	return self;
}

#pragma mark -
#pragma mark Lazy Load

- (NSMutableArray<NSError *> *)internalErrors {
	if (!_internalErrors) {
		_internalErrors = [NSMutableArray array];
	}
	return _internalErrors;
}

- (MADMutableOperationConditions *)conditions {
	if (!_conditions) {
		_conditions = [NSMutableArray array];
	}
	return _conditions;
}

- (MADMutableOperationObservers *)observers {
	if (!_observers) {
		_observers = [NSMutableArray array];
	}
	return _observers;
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
	pthread_mutex_lock(&_stateLock);
	MADOperationState currentState = _state;
	pthread_mutex_unlock(&_stateLock);
	return currentState;
}

- (void)setState:(MADOperationState)newState {
	pthread_mutex_lock(&_stateLock);
	if (_state == newState || _state == MADOperationStateFinished) {
		pthread_mutex_unlock(&_stateLock);
		return;
	}
	
	os_log_info(OS_LOG_DEFAULT, "[OP:%lu (%@)] State changing from %s to %s", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class), MADStringOperationState(_state), MADStringOperationState(newState));
	
	[self willChangeValueForKey:MADOperatorSelectorState];
	_state = newState;
	[self didChangeValueForKey:MADOperatorSelectorState];
	pthread_mutex_unlock(&_stateLock);
}

- (void)willEnqueue { self.state = MADOperationStatePending; }

+ (NSString *)descriptionForState:(MADOperationState)state {
	switch (state) {
		case MADOperationStateReady:
			return @"Ready";
			break;
		case MADOperationStatePending:
			return @"Pending";
			break;
		case MADOperationStateFinished:
			return @"Finished";
			break;
		case MADOperationStateFinishing:
			return @"Finishing";
			break;
		case MADOperationStateExecuting:
			return @"Executing";
			break;
		case MADOperationStateInitialized:
			return @"Initalized";
			break;
		case MADOperationStateEvaluatingConditions:
			return @"Evaluating Conditions";
			break;
		default:
			return @"Unknown";
			break;
	}
}

- (BOOL)isReady {
	MADOperationState currentState = self.state; // Avoid recursive lock
	os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] Checking isReady. Current state: %s, isCancelled: %{BOOL}d, super.isReady: %{BOOL}d", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class), MADStringOperationState(currentState), self.cancelled, super.ready);
	
	switch (currentState) {
		case MADOperationStateInitialized:
			os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] isReady: Initialized. Returning based on self.cancelled: %{BOOL}d", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class), self.cancelled);
			return self.cancelled;
			
		case MADOperationStatePending:
			if (self.cancelled) {
				os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] isReady: Pending & Cancelled. Returning YES.", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class));
				return YES;
			}
			if (super.ready) {
				os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] isReady: Pending & super.isReady. Evaluating conditions.", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class));
				[self evaluateConditions]; // This will change state
				os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] isReady: Conditions evaluated. New state: %s. Returning %{BOOL}d", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class), MADStringOperationState(self.state), self.state == MADOperationStateReady);
				return self.state == MADOperationStateReady; // Check the new state
			}
			os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] isReady: Pending & NOT super.isReady. Returning NO.", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class));
			return NO;
			
		case MADOperationStateReady:
			os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] isReady: Already in Ready state or Cancelled. Returning %{BOOL}d", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class), super.ready || self.cancelled);
			return super.ready || self.cancelled;
			
		default:
			os_log_debug(GetFoundationLog(), "[OP:%lu (%@)] isReady: Default case (state: %s). Returning NO.", (unsigned long)self.identifier, self.name ?: NSStringFromClass(self.class), MADStringOperationState(currentState));
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

- (void)addCondition:(nonnull NSObject<MADOperationCondition> *)condition {
	NSAssert(self.state < MADOperationStateEvaluatingConditions, @"Cannot modify observers after execution has begun.");
	[self.conditions addObject:condition];
}

- (void)addConditions:(nonnull NSArray<NSObject<MADOperationCondition> *> *)conditions {
	[self.conditions addObjectsFromArray:conditions];
}

- (void)addDependency:(NSOperation *)op {
	NSAssert(self.state < MADOperationStateExecuting, @"Dependencies cannot be modified after execution has begun.");
	[super addDependency:op];
}

#pragma mark -
#pragma mark Observers

- (void)addObserver:(nonnull NSObject<MADOperationObserver> *)observer {
	NSAssert(self.state < MADOperationStateExecuting, @"Cannot modify observers after execution has begun.");
	[self.observers addObject:observer];
}

- (void)addObservers:(nonnull NSArray<NSObject<MADOperationObserver> *> *)observers {
	[self.observers addObjectsFromArray:observers];
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
