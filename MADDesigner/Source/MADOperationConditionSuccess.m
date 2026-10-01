//
//  MADOperationConditionSuccess.m
//  MAD Designer
//
//  Created by Michael on 8/17/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionSuccess.h"
#import <os/log.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSArray.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADOperationTestResults.h>

@interface MADOperationConditionSuccess ()

	@property (nonatomic, readwrite, copy) NSString *key;

@end


@implementation MADOperationConditionSuccess

- (void)dealloc { }

- (instancetype)initWithKey:(NSString *)key {
	if (self = [super init]) {
		_key = key.copy;
		_reverseCondition = NO;
	}
	return self;
}

#pragma mark -
#pragma mark Condition

- (NSString *)name {
	return NSStringFromClass(super.class);
}

- (BOOL)isMutuallyExclusive {
	return NO;
}

- (NSOperation *)dependencyForOperation:(MADOperation *)operation {
	return nil;
}

- (void)evaluateForOperation:(MADOperation *)operation
				  completion:(void (^)(MADOperationConditionResult *))completion {
	MADOperationConditionResult *result = [self evaluateForOperation:operation];
	completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
	MADOperationConditionResult *result = nil;
	if (dependencies.count == 0) {
		result = [self result: NO];
		return result;
	}
	
	for (MADOperation *dependency in dependencies) {
		if (![dependency conformsToProtocol:@protocol(MADOperationTestResults)]) {
			continue;
		}
		NSString *dependencyName = ((MADOperation <MADOperationTestResults> *) dependency).name;
		if (dependencyName != nil && [_key isEqualToString: dependencyName]) {
			result = [self result: ((NSObject <MADOperationTestResults> *)dependency).success];
			break;
		}
	}
	// No dependency matched: fail quietly. This used to be an NSAssert, which aborted
	// the calling operation in Debug while Release, where NS_ASSERTIONS compiles out,
	// fell through to the same failure the line below returns.
	return result != nil ? result : [self result: NO];
}

- (MADOperationConditionResult *)result:(BOOL)success {
	return _reverseCondition ?
			(success ?
				[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name] :
				[MADOperationConditionResult newOperationConditionResultSatisfied]) :
			(success ?
				[MADOperationConditionResult newOperationConditionResultSatisfied] :
				[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name]);
}

@end
