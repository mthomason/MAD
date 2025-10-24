//
//  MADOperationConditionTestConnectionSuccess.m
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionTestConnectionSuccess.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSOperation.h>

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>

#import <MADFoundation/MADOperationTestResults.h>

@implementation MADOperationConditionTestConnection

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(super.class); }
- (BOOL)isMutuallyExclusive { return NO; }
- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
	MADOperationConditionResult *result = [self evaluateForOperation:operation];
	if (completion != nil) completion(result);
}

- (BOOL)evaludateForOperationSimple:(MADOperation *)operation {
	NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
	BOOL result = NO;
	
	if (dependencies.count == 0) {
		result = NO;
		return result;
	}
	
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationTestResults)]) {
			NSObject <MADOperationTestResults> *testConnection;
			testConnection = (NSObject <MADOperationTestResults> *)dependency;
			if (testConnection) {
				if (testConnection.isSuccess) {
					result = YES;
				} else {
					result = NO;
				}
				break;
			}
		}
	}
	return result;
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	return nil;
}

@end

@implementation MADOperationConditionTestConnectionSuccess

- (NSString *)name { return NSStringFromClass(self.class); }

#pragma mark - Condition

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	return [super evaludateForOperationSimple:operation] ?
		[MADOperationConditionResult newOperationConditionResultSatisfied] :
		[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
}

@end

@implementation MADOperationConditionTestConnectionFailuare

- (NSString *)name { return NSStringFromClass(self.class); }

#pragma mark - Condition

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	return [super evaludateForOperationSimple:operation] ?
		[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name] :
		[MADOperationConditionResult newOperationConditionResultSatisfied];
}

@end
