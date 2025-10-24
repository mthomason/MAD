//
//  MADOperationConditionSupport.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionResult.h"
#import "madlog.h"

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSError.h>

NSString * _Nonnull const MADOperationConditionKey = @"OperationCondition";

@interface MADOperationConditionResult ()

	@property (nonatomic, assign) BOOL isSucceed;
	@property (nonatomic, strong, nullable) NSError * error;

@end

@implementation MADOperationConditionResult

#pragma mark - Factory Methods

+ (nonnull instancetype)newOperationConditionResultSatisfied {
	MADLogDebug("MADOperationConditionResult: created 'satisfied'.");
	return [self newOperationConditionResultIsSucceed:YES error:nil];
}

+ (nonnull instancetype)newOperationConditionResult:(BOOL)satisfied {
	MADLogDebug("MADOperationConditionResult: created with satisfied: %s", satisfied ? "YES" : "NO");
	return [self newOperationConditionResult:satisfied name:NSStringFromClass(self.class)];
}

+ (nonnull instancetype)newOperationConditionResult:(BOOL)satisfied name:(nonnull NSString *)name {
	MADLogDebug("MADOperationConditionResult: created for name \"%@\" with satisfied: %s",
				name, satisfied ? "YES" : "NO");
	if (satisfied) {
		return [self newOperationConditionResultSatisfied];
	} else {
		return [self newOperationConditionResultFailedNotSatisfied:name];
	}
}

+ (nonnull instancetype)newOperationConditionResultFailedNotSatisfied:(nonnull NSString *)name {
	MADLogDebug("MADOperationConditionResult: created 'failed' (not satisfied) for condition name: \"%@\"", name);
	NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-82795 userInfo:@{
		NSLocalizedFailureReasonErrorKey: @"Not Satisfied",
		NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Condition '%@' not Satisfied", name],
		MADOperationConditionKey: name
	}];
	return [self newOperationConditionResultFailed:error];
}

+ (nonnull instancetype)newOperationConditionResultFailed:(nonnull NSError *)error {
	if (!error) {
		// This situation (a "failed" result created with a nil error) might indicate a programming error.
		MADLogError("MADOperationConditionResult: newOperationConditionResultFailed called with nil error. Creating generic failure for programming issue tracking. This should be investigated.");
		error = [NSError errorWithDomain:NSStringFromClass(self) code:32874 userInfo:@{
			NSLocalizedFailureReasonErrorKey: @"Internal Error",
			NSLocalizedDescriptionKey: @"Condition failed with an unspecified error."
		}];
	}
	MADLogDebug("MADOperationConditionResult: created 'failed' with error: %@", error);
	return [self newOperationConditionResultIsSucceed:NO error:error];
}

+ (nonnull instancetype)newOperationConditionResultIsSucceed:(BOOL)isSucceed
													   error:(nullable NSError *)error {
	MADOperationConditionResult *newResult = [[self alloc] init];
	newResult.isSucceed = isSucceed;
	newResult.error = error;
	return newResult;
}

#pragma mark - Lifecycle

- (void)dealloc {
	// No-op
}

- (nonnull instancetype)init {
	if (self = [super init]) {
		_isSucceed = NO;
		_error = nil;
	}
	return self;
}

#pragma mark - Error Handling

- (nullable NSError *)error {
	return _isSucceed ? nil : _error;
}

+ (void)evaluateConditions:(nonnull NSArray<id<MADOperationCondition>> *)conditions
				 operation:(nonnull MADOperation *)operation
			   completion:(nonnull void(^)(NSArray<NSError *> * _Nonnull errors))completion {
	MADLogDebug("MADOperationConditionResult: Op <%p:%@> evaluating %lu conditions.", operation, operation.name, (unsigned long)conditions.count);

	dispatch_group_t conditionGroup = dispatch_group_create();
	NSMutableArray<MADOperationConditionResult *> *results = [NSMutableArray arrayWithCapacity:conditions.count];

	if (conditions.count == 0) {
		MADLogDebug("MADOperationConditionResult: Op <%p:%@> no conditions to evaluate.", operation, operation.name);
		if (completion != nil) {
			completion(@[]);
		}
		return;
	}
	
	for (id<MADOperationCondition> condition in conditions) {
		MADLogDebug("MADOperationConditionResult: Op <%p:%@> evaluating condition: \"%@\"", operation, operation.name, [condition name]);
		dispatch_group_enter(conditionGroup);
		[condition evaluateForOperation:operation
							 completion:^(MADOperationConditionResult * _Nonnull result) {
			MADLogDebug("MADOperationConditionResult: Op <%p:%@> condition \"%@\" completed. Succeeded: %s. Error: %@",
						operation, operation.name, [condition name],
						result.isSucceed ? "YES" : "NO", result.error);
			@synchronized (results) { // Basic safety for NSMutableArray if callbacks are concurrent
				[results addObject:result];
			}
			dispatch_group_leave(conditionGroup);
		}];
	}
	
	dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		MADLogDebug("MADOperationConditionResult: Op <%p:%@> all %lu conditions finished evaluation phase.",
					operation, operation.name, (unsigned long)conditions.count);
		
		NSArray<MADOperationConditionResult *> *finalResults;
		@synchronized (results) {
			finalResults = [results copy]; // Work with a copy
		}
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"error != nil"];
		NSArray<NSError *> *failures = [[finalResults filteredArrayUsingPredicate:predicate] valueForKeyPath:@"error"];
		if (!failures) { // valueForKeyPath can return nil if path is invalid or collection empty
			failures = [NSMutableArray array];
		}
		MADLogDebug("MADOperationConditionResult: Op <%p:%@> found %lu direct condition failures.",
					operation, operation.name, (unsigned long)failures.count);
		if (operation.isCancelled) {
			MADLogDebug("MADOperationConditionResult: Op <%p:%@> was cancelled during condition evaluation, adding cancellation error.",
						operation, operation.name);
			failures = [failures arrayByAddingObject:[NSError errorWithDomain:@"OperationErrors" code:-82796 userInfo:nil]];
		}
		
		if (completion != nil) {
			MADLogDebug("MADOperationConditionResult: Op <%p:%@> completing evaluation with %lu total error(s).",
						operation, operation.name, (unsigned long)failures.count);
			completion([failures copy]);
		}
	});
}

@end
