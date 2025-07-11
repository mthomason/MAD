//
//  MADOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADOperationObserver.h>

#import "MADBlockObserver.h"
#import "madlog.h"

#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>

#import <UIKit/UIApplication.h>	// Wish I didn't have to import UIApplication here, but it's really the cleanest way.

#import <os/log.h>
#import <pthread.h>

static NSString * const MADOperatorSelectorIsReady      = @"isReady";
static NSString * const MADOperatorSelectorIsExecuting  = @"isExecuting";
static NSString * const MADOperatorSelectorIsFinished   = @"isFinished";
static NSString * const MADOperatorSelectorState        = @"state";

@interface MADOperation()
@property (nonatomic, strong) NSMutableArray <NSError *> *internalErrors;
@property (nonatomic, strong) NSMutableArray <NSError *> *errors;
@property (atomic, assign) BOOL hasFinishedAlready;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
// _state is defined in @implementation block
@end

@implementation MADOperation {
	MADOperationState _state;
	pthread_mutex_t _stateLock;
}

#pragma mark -
#pragma mark Static functions

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
		
		// self.name might not be fully resolved here (could be NSOperation's default)
		// self.identifier is not set yet.
		MADLogDebug("MADOperation <%p> init. Initial state: %@", self, NSStringFromMADOperationState(_state));
	}
	return self;
}

- (void)dealloc {
	MADLogDebug("MADOperation <%p:%@> dealloc. Final state: %@", self, self.name, NSStringFromMADOperationState(_state));
	// Clean up the mutex
	pthread_mutex_destroy(&_stateLock);
	// _conditions, _observers, _internalErrors will be released automatically.
}

#pragma mark -
#pragma mark Lazy Load

- (NSMutableArray<NSError *> *)errors {
	if (!_errors) {
		_errors = [NSMutableArray array];
	}
	return _errors;
}

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
#pragma mark KVO & State Management

- (MADOperationState)state {
	pthread_mutex_lock(&_stateLock);
	MADOperationState currentState = _state;
	pthread_mutex_unlock(&_stateLock);
	return currentState;
}

- (void)setState:(MADOperationState)newState {
	// Lock early to read _state safely
	pthread_mutex_lock(&_stateLock);
	MADOperationState oldState = _state;
	
	if (oldState == MADOperationStateFinished) {
		MADLogDebug("MADOperation <%p:%@> setState: Attempt to change state from Finished (%@) to %@. Denied.",
					self, self.name, NSStringFromMADOperationState(oldState), NSStringFromMADOperationState(newState));
		pthread_mutex_unlock(&_stateLock);
		return;
	}
	if (oldState == newState) {
		MADLogDebug("MADOperation <%p:%@> setState: Attempt to change state to current state %@. No change.",
					self, self.name, NSStringFromMADOperationState(oldState));
		pthread_mutex_unlock(&_stateLock);
		return;
	}
	
	// Use will/didChangeValueForKey for KVO compliance on 'state'
	// These must be called OUTSIDE the lock if they can trigger arbitrary code (observers)
	// that might try to re-lock. However, NSOperation's KVO is usually about notifying
	// the OperationQueue, which is designed to handle it.
	// For now, assuming current lock scope is fine as per original code.
	// A safer pattern is unlock-notify-relock if KVO observers are complex.
	// But given it's a recursive lock, direct re-entrancy is safe.
	
	MADLogDebug("MADOperation <%p:%@> state changing: %@ -> %@",
				self, self.name, NSStringFromMADOperationState(oldState), NSStringFromMADOperationState(newState));
	
	[self willChangeValueForKey:MADOperatorSelectorState];
	_state = newState;
	[self didChangeValueForKey:MADOperatorSelectorState];
	
	pthread_mutex_unlock(&_stateLock);
}

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

- (void)willEnqueue {
	MADLogDebug("MADOperation <%p:%@> willEnqueue.", self, self.name);
	self.state = MADOperationStatePending;
}

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
	// This method can be called frequently. Verbose logging here should be conditional or very lightweight.
	MADOperationState currentState = self.state; // Accesses property, which locks/unlocks
	BOOL currentIsCancelled = self.isCancelled; // Accesses super, presumably safe
	
	// MADLogDebug("MADOperation <%p:%@> isReady? Current state: %@, Cancelled: %s",
	// 			self, self.name, NSStringFromMADOperationState(currentState), currentIsCancelled ? "YES" : "NO");
	
	switch (currentState) {
		case MADOperationStateInitialized:
			return currentIsCancelled; // If cancelled before pending, it can be considered "ready" to finish.
			
		case MADOperationStatePending:
			if (currentIsCancelled) {
				MADLogDebug("MADOperation <%p:%@> isReady: YES (pending but cancelled)", self, self.name);
				return YES;
			}
			if ([super isReady]) { // Check dependencies
				MADLogDebug("MADOperation <%p:%@> isReady: Super is ready, evaluating conditions.", self, self.name);
				[self evaluateConditions]; // This will transition state internally
				// State might have changed to EvaluatingConditions, then to Ready.
				// Re-check self.state after evaluateConditions (which is async).
				// This logic is tricky: isReady should be synchronous. evaluateConditions is async.
				// NSOperationQueue polls isReady. If evaluateConditions is async,
				// isReady might return NO, then YES later once conditions pass.
				// The current implementation relies on evaluateConditions synchronously changing state if all conditions are synchronous,
				// or eventually changing it. The `self.state == MADOperationStateReady` check after
				// `evaluateConditions` implies an expectation of synchronous change or that `evaluateConditions`
				// is called to *initiate* the check, and the queue will poll again.
				return self.state == MADOperationStateReady;
			}
			return NO; // Dependencies not met
			
		case MADOperationStateReady:
			return YES; // Explicitly ready (or super.isReady || self.isCancelled if super matters here)
			
		default:
			return NO; // Not in a ready-able state (Executing, Finishing, Finished)
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
	// NSAssert is a form of self-documentation and debug check.
	//NSAssert(self.state == MADOperationStatePending && !self.isCancelled, @"evaluateConditions() was called out-of-order");
	
	MADLogDebug("MADOperation <%p:%@> evaluateConditions: changing state to EvaluatingConditions.", self, self.name);
	self.state = MADOperationStateEvaluatingConditions;
	
	MADOperation __weak *weakSelf = self; // Use __weak for blocks
	[MADOperationConditionResult evaluateConditions:self.conditions
										  operation:self
										 completion:^(NSArray *failures) {
		MADOperation *strongSelf = weakSelf;
		if (!strongSelf) {
			MADLogDebug("MADOperation evaluateConditions completion: self is nil (op likely deallocated).");
			return;
		}
		
		if (failures.count > 0) {
			MADLogError("MADOperation <%p:%@> condition evaluation completed with %lu error(s):",
						strongSelf, strongSelf.name, (unsigned long)failures.count);
			for (NSError *error in failures) {
				MADLogError("  Op <%p:%@> Condition Error: %@", strongSelf, strongSelf.name, error);
			}
			[strongSelf.internalErrors addObjectsFromArray:failures];
		} else {
			MADLogDebug("MADOperation <%p:%@> condition evaluation completed with no errors.",
						strongSelf, strongSelf.name);
		}
		
		// Only transition to Ready if not cancelled AFTER conditions evaluated.
		if (strongSelf.isCancelled) {
			MADLogDebug("MADOperation <%p:%@> conditions evaluated, but operation is now cancelled. Will transition to finish.", strongSelf, strongSelf.name);
			// The isReady logic or start logic should handle this by moving to finish.
			// Setting state to Ready might be okay, as a cancelled op that's "Ready" will just finish quickly.
			// However, if it's cancelled, perhaps it should go straight to Finishing/Finished.
			// For now, follow original logic of setting to Ready.
			strongSelf.state = MADOperationStateReady; // Or perhaps a specific "CancelledAfterConditions" state if needed.
		} else {
			strongSelf.state = MADOperationStateReady;
		}
	}];
}

#pragma mark -
#pragma mark Conditions

- (void)addCondition:(nonnull NSObject<MADOperationCondition> *)condition {
	NSAssert(self.state < MADOperationStateEvaluatingConditions, @"Cannot modify conditions after evaluation has begun.");
	MADLogDebug("MADOperation <%p:%@> addCondition: %@", self, self.name, [condition respondsToSelector:@selector(name)] ? [condition name] : NSStringFromClass([condition class]));
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
	MADLogDebug("MADOperation <%p:%@> addObserver: %@", self, self.name, NSStringFromClass([observer class]));
	[self.observers addObject:observer];
}

- (void)addObservers:(nonnull NSArray<NSObject<MADOperationObserver> *> *)observers {
	[self.observers addObjectsFromArray:observers];
}

#pragma mark -
#pragma mark Execution and Cancellation

- (void)start {
	// NSOperation's start is complex. It typically involves KVO notifications.
	// This override needs to be careful.
	MADLogDebug("MADOperation <%p:%@> start called. Current state: %@. isReady: %s. isCancelled: %s",
				self, self.name, NSStringFromMADOperationState(self.state),
				self.isReady ? "YES" : "NO", self.isCancelled ? "YES" : "NO");
	
	// According to NSOperation behavior, `start` should not call `main` directly
	// if it's managed by an NSOperationQueue. The queue calls `main` after `start`
	// has done its setup (like changing to isExecuting=YES).
	// However, this class has its own state machine.
	// The original code:
	// if (self.isReady) { [self main]; } else if (self.cancelled) { [self finish]; }
	// This is okay for a concurrent operation that manages its own transition to finished/executing.
	
	// Ensure KVO for isExecuting is managed if not calling super.start() which would handle it.
	// This implementation seems to bypass super.start() and directly call main or finish.
	// This implies it's a concurrent operation (isConcurrent returns YES or NSOperation assumes it if start is overidden this way).
	// Typically, for a concurrent op, you'd set isExecuting=YES, isFinished=NO here before main.
	
	// Given that self.state handles KVO for isExecuting/isFinished, this might be fine.
	// The check for self.isReady is key. If it's ready, it proceeds to main.
	// If already cancelled, it finishes.
	
	if (self.isCancelled) {
		MADLogDebug("MADOperation <%p:%@> start: Operation is cancelled, finishing.", self, self.name);
		[self finish];
		return;
	}
	
	if (self.isReady) {
		MADLogDebug("MADOperation <%p:%@> start: Operation is ready, calling main.", self, self.name);
		[self main];
	} else {
		MADLogDebug("MADOperation <%p:%@> start: Operation is not ready (state: %@) and not cancelled. Start will not proceed to main at this time.",
					self, self.name, NSStringFromMADOperationState(self.state));
		// NSOperationQueue will keep polling isReady.
	}
}

- (void)main {
	NSAssert(self.state == MADOperationStateReady, @"This operation must be performed on an operation queue or after reaching Ready state.");
	MADLogDebug("MADOperation <%p:%@> main called. Cancelled: %s, InternalErrors: %lu",
				self, self.name, self.isCancelled ? "YES" : "NO", (unsigned long)self.internalErrors.count);
	[self beginBackgroundTask];
	if (!self.isCancelled && self.internalErrors.count == 0) {
		self.state = MADOperationStateExecuting;
		
		MADLogDebug("MADOperation <%p:%@> main: Notifying observers operationDidStart.", self, self.name);
		for (NSObject <MADOperationObserver> *observer in self.observers) {
			[observer operationDidStart:self];
		}
		
		MADLogDebug("MADOperation <%p:%@> main: Calling execute.", self, self.name);
		[self execute];
	} else {
		MADLogDebug("MADOperation <%p:%@> main: Operation cancelled or has errors, finishing.", self, self.name);
		[self finish];
	}
}

- (void)execute {
	MADLogDebug("MADOperation <%p:%@> execute (base implementation). Finishing.", self, self.name);
	[self finish]; // Default behavior is to finish immediately.
}

- (void)cancelWithError:(nullable NSError *)error {
	if (error) {
		MADLogError("MADOperation <%p:%@> cancelling with error: %@", self, self.name, error);
		// Access internalErrors within a lock if it can be modified/accessed elsewhere concurrently
		// For now, assuming addObjectsFromArray is internally safe enough or access is serialized.
		NSError *errorCopy = [error copy];
		[self.internalErrors addObject:errorCopy];
	} else {
		MADLogDebug("MADOperation <%p:%@> cancelling without specific error.", self, self.name);
	}
	[super cancel]; // Call super's cancel to trigger KVO for isCancelled etc.
	MADLogDebug("MADOperation <%p:%@> did call super.cancel. isCancelled is now: %s", self, self.name, self.isCancelled ? "YES" : "NO");
	
	// If an operation is cancelled, it might need to transition its state quickly
	// especially if it's pending or evaluating conditions.
	// The NSOperation's isCancelled KVO should allow isReady to become true,
	// and then start/main will call finish.
}

- (void)produceOperation:(nonnull NSOperation *)operation {
	MADLogDebug("MADOperation <%p:%@> produceOperation: %@. Notifying %lu observers.",
				self, self.name, operation, (unsigned long)self.observers.count);
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

- (void)finishWithError:(nullable NSError *)error {
	if (error) {
		NSError *nonNullError = [error copy];
		[self finish:@[nonNullError]];
	} else {
		[self finish:nil];
	}
}

- (void)finish:(nullable NSArray<NSError *> *)errors {
	if (!self.hasFinishedAlready) { // Check within lock or make hasFinishedAlready atomic if needed
		// Original code sets hasFinishedAlready = YES inside the if block.
		// This is generally okay if finish is called from one place after decision.
		pthread_mutex_lock(&_stateLock); // Protect hasFinishedAlready and state transitions
		if (_hasFinishedAlready) {
			pthread_mutex_unlock(&_stateLock);
			MADLogDebug("MADOperation <%p:%@> finish: Already finished, ignoring call.", self, self.name);
			return;
		}
		_hasFinishedAlready = YES;
		// Unlock before KVO and observer notifications if they could cause re-entrancy issues not covered by recursive lock
		// For now, keeping recursive lock around the whole block as per likely original intent.
		MADLogDebug("MADOperation <%p:%@> finish with %lu direct errors. Current internal errors: %lu",
					self, self.name, (unsigned long)(errors ? errors.count : 0), (unsigned long)self.internalErrors.count);
		
		// State transition to Finishing must happen before notifying observers
		// (willChangeValueForKey for 'state' happens in setState)
		// Store old state for logging if needed, before it's changed to Finishing
		MADOperationState stateBeforeFinishing = _state; // Read while locked
		pthread_mutex_unlock(&_stateLock); // Unlock before KVO-heavy setState and observer calls
		
		self.state = MADOperationStateFinishing; // This will lock/unlock itself
		
		NSMutableArray<NSError *> *combinedErrors = [NSMutableArray arrayWithArray:self.internalErrors];
		if ([errors count] > 0) {
			NSArray *errorsStrong = errors;
			[combinedErrors addObjectsFromArray:errorsStrong];
			[self.errors addObjectsFromArray:errorsStrong];
		}
		
		if (combinedErrors.count > 0) {
			MADLogError("MADOperation <%p:%@> finishing with a total of %lu error(s):",
						self, self.name, (unsigned long)combinedErrors.count);
			for (NSError *err in combinedErrors) {
				MADLogError("  Op <%p:%@> Finish Error: %@", self, self.name, err);
			}
		} else {
			MADLogDebug("MADOperation <%p:%@> finishing with no errors.", self, self.name);
		}
		
		MADLogDebug("MADOperation <%p:%@> calling 'finished:' from state %ld (subclass override point).", self, self.name, (long)stateBeforeFinishing);
		[self finished:[combinedErrors copy]]; // Pass immutable copy
		
		MADLogDebug("MADOperation <%p:%@> notifying observers operationDidFinish.", self, self.name);
		NSArray *currentObservers = [self.observers copy]; // Copy for safe iteration
		for (NSObject <MADOperationObserver> *observer in currentObservers) {
			[observer operationDidFinish:self errors:[combinedErrors copy]];
		}
		
		self.state = MADOperationStateFinished; // This will lock/unlock itself
	} else {
		MADLogDebug("MADOperation <%p:%@> finish: Already finished (checked again).", self, self.name);
	}
}

/**
 Subclasses may override `finished(_:)` if they wish to react to the operation
 finishing with errors. For example, the `LoadModelOperation` implements
 this method to potentially inform the user about an error when trying to
 bring up the Core Data stack.
 */
- (void)finished:(NSArray *)errors {
	MADLogDebug("MADOperation <%p:%@> 'finished:' (base override point) called with %lu errors.",
				self, self.name, (unsigned long)errors.count);
	[self endBackgroundTask];
	// This is a no-op by default. Subclasses may override this method to
	// perform any cleanup or finalization tasks.
	// For example, you might want to remove any temporary files or
	// undo any changes made during the operation.
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
	NSAssert(NO, @"Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.");
}

- (void)cleanup {
	MADLogDebug("MADOperation <%p:%@> cleanup called. Dependencies: %lu, Conditions: %lu, Observers: %lu",
				self, self.name, (unsigned long)self.dependencies.count,
				(unsigned long)self.conditions.count, (unsigned long)self.observers.count);
	
	NSArray <NSOperation *> *dependencies = [self.dependencies copy]; // Iterate on a copy
	for (NSOperation *dependency in dependencies) {
		[self removeDependency:dependency];
	}
	
	[self.conditions removeAllObjects];
	[self.observers removeAllObjects];
	[self.internalErrors removeAllObjects]; // Also clear internal errors
	MADLogDebug("MADOperation <%p:%@> cleanup complete.", self, self.name);
}

- (NSString *)name {
	// Override NSOperation's name property to provide a more descriptive,
	// unique identifier for debugging.
	return [NSString stringWithFormat:@"%@_%p", NSStringFromClass(self.class), self];
}

#pragma mark -
#pragma mark Background Task Management

- (void)beginBackgroundTask {
	self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:[self name] expirationHandler:^{
		// The OS is about to kill the app. We must end our task.
		MADLogError("Background time expired for operation: %@", [self name]);
		[self endBackgroundTask];
	}];
	MADLogInfo("Background task started for operation: %@", [self name]);
}

- (void)endBackgroundTask {
	// This check prevents us from trying to end an invalid task.
	if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
		MADLogInfo("Ending background task for operation: %@", [self name]);
		[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
		self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
	}
}

@end
