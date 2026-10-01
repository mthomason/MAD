//
//  MADOperationConditionDisplayedAlertConfirm.m
//  MAD Designer
//
//  Created by Michael on 8/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionDisplayedAlertConfirm.h"
#import "MADOperationConditionDisplayedAlert.h"
#import "madlog.h"

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>

#import <MAD/MADOperationHoldsCredentialsProtocol.h>

#import <Foundation/NSArray.h>

@implementation MADOperationConditionDisplayedAlertConfirm

@synthesize reverseCondition = _reverseCondition;

- (instancetype)init {
	if (self = [super init]) {
		_reverseCondition = NO;
	}
	return self;
}

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }


- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
	MADOperationConditionResult *result = [self evaluateForOperation:operation];
	completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
	
	if (dependencies.count == 0) {
		return [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
	}
	
	MADOperationConditionResult *result = nil;
	for (MADOperation *dependency in dependencies) {
		
		if ([dependency conformsToProtocol:@protocol(MADOperationConditionDisplayedAlertProtocol)]) {
			
			BOOL condition = [((NSObject <MADOperationConditionDisplayedAlertProtocol> *)dependency) alertDisplayedAffirmed];
			result = [MADOperationConditionResult newOperationConditionResult: _reverseCondition ? !condition : condition
																		 name: self.name];
			break;
			
		} else if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
			BOOL condition = [((NSObject <MADOperationHoldsCredentialsProtocol> *)dependency) manuallyInputtedCredentials];
			result = [MADOperationConditionResult newOperationConditionResult: _reverseCondition ? !condition : condition
																		 name: self.name];
			break;
		}
	}
	// Dependencies exist but none of them can answer. This used to return nil from a
	// method declared nonnull; the empty-dependency case above already reports the same
	// failure properly.
	return result != nil ? result : [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
}

@end
