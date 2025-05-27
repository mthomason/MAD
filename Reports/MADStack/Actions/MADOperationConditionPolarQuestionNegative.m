//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionPolarQuestionNegative.h"
#import "MADOperationPromptPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "madlog.h"

#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

@interface MADOperationConditionPolarQuestionNegative ()

@property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionPolarQuestionNegative

- (void)dealloc { }

- (instancetype)initWithOperationIdentifier:(NSUInteger)tag {
	if (self = [super init]) {
		_tag = tag;
	}
	return self;
}

#pragma mark -
#pragma mark Condition

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation
				  completion:(void (^)(MADOperationConditionResult *))completion {
	MADOperationConditionResult *result = [self evaluateForOperation:operation];
	completion(result);
}


- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
	MADOperationConditionResult *result = nil;
	
	if (dependencies.count == 0) {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
		return result;
	}

	for (MADOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
			dependency.identifier == self.tag) {
			result = [MADOperationConditionPolarQuestionNegativeResult newOperationCondition: (NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency
																						name: self.name];
			break;
		}
	}
	if (result != nil) {
		return result;
	} else {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
		return  result;
	}
	
}

@end
