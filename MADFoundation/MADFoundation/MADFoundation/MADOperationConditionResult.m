//
//  MADOperationConditionSupport.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionResult.h"
#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>

NSString * _Nonnull const MADOperationConditionKey = @"OperationCondition";

@interface MADOperationConditionResult ()

	@property (nonatomic, assign) BOOL isSucceed;
	@property (nonatomic, strong, nullable) NSError * error;

@end

@implementation MADOperationConditionResult

#pragma mark - Factory Methods

+ (nonnull instancetype)newOperationConditionResultSatisfied {
	return [self newOperationConditionResultIsSucceed:YES error:nil];
}

+ (nonnull instancetype)newOperationConditionResult:(BOOL)satisfied {
	return [self newOperationConditionResult:satisfied name:NSStringFromClass(self.class)];
}

+ (nonnull instancetype)newOperationConditionResult:(BOOL)satisfied name:(nonnull NSString *)name {
	if (satisfied) {
		return [self newOperationConditionResultSatisfied];
	} else {
		return [self newOperationConditionResultFailedNotSatisfied:name];
	}
}

+ (nonnull instancetype)newOperationConditionResultFailedNotSatisfied:(nonnull NSString *)name {
	NSString *message = @"Not Satisfied";
	MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:message
																   andMessage:message];
	NSError *error = [errorUserInfo errorWithDomain:name code:MADConditionFailed];
	return [self newOperationConditionResultFailed:error];
}

+ (nonnull instancetype)newOperationConditionResultFailed:(nonnull NSError *)error {
	if (!error) {
		error = [NSError errorWithDomain:NSStringFromClass(self) code:32874 userInfo:nil];
	}
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
	// Check conditions.
	dispatch_group_t conditionGroup = dispatch_group_create();
	
	// Array to store results of condition evaluations.
	NSMutableArray<MADOperationConditionResult *> *results =
	[NSMutableArray arrayWithCapacity:conditions.count];
	
	// Ask each condition to evaluate and store its result in the "results" array.
	for (id<MADOperationCondition> condition in conditions) {
		dispatch_group_enter(conditionGroup);
		[condition evaluateForOperation:operation
							 completion:^(MADOperationConditionResult * _Nonnull result) {
			[results addObject:result];
			dispatch_group_leave(conditionGroup);
		}];
	}
	
	// After all the conditions have evaluated, this block will execute.
	dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		// Aggregate the errors that occurred, in order.
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"error != nil"];
		NSArray<NSError *> *failures = [[results filteredArrayUsingPredicate:predicate] valueForKeyPath:@"error"];
		
		// If the operation was cancelled, add a cancellation error.
		if (operation.isCancelled) {
			NSError *cancellationError = [NSError errorWithCode:MADConditionFailed];
			failures = [failures arrayByAddingObject:cancellationError];
		}
		
		// Call the completion block with the aggregated errors.
		if (completion) {
			completion(failures);
		}
	});
}

@end
