//
//  MADOperationConditionDisplayedAlert.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/20/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionDisplayedAlert.h"
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <os/log.h>

@interface MADOperationConditionDisplayedAlert ()

	@property (nonatomic, assign, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionDisplayedAlert

@synthesize reverseCondition = _reverseCondition;

- (void)dealloc { }

- (instancetype)initWithOperationIdentifier:(NSUInteger)tag {
	if (self = [super init]) {
		_tag = tag;
		_reverseCondition = NO;
	}
	return self;
}

#pragma mark -
#pragma mark Condition

- (NSString *)name {
	NSString *name = NSStringFromClass(self.class);
	return name;
}

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
	MADOperationConditionResult *result;
	result = [self evaluateForOperation:operation];
	completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	NSArray <__kindof NSOperation *> *dependencies = operation.dependencies;
	MADOperationConditionResult *result = nil;
	NSString *domain = self.name.copy;
	if (dependencies.count == 0) {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:domain];
		return result;
	}

	for (MADOperation *dependency in dependencies) {
		
		if ([dependency conformsToProtocol:@protocol(MADOperationConditionDisplayedAlertProtocol)] &&
			dependency.identifier == self.tag) {
			
			BOOL condition = [((NSObject <MADOperationConditionDisplayedAlertProtocol> *)dependency) alertDisplayed];
			result = [MADOperationConditionResult newOperationConditionResult: _reverseCondition ? !condition : condition
																		 name: domain];
			
			break;
		}
	}
	
	if (result == nil) {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:domain];
	}
	return result;
}

@end
