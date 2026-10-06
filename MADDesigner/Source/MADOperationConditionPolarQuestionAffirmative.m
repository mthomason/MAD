//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationPromptPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import <MADFoundation/madlog.h>

#import <MADFoundation/MADOperationConditionResult.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

#import <asl.h>

@interface MADOperationConditionPolarQuestionAffirmative ()

@property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionPolarQuestionAffirmative

- (void)dealloc { }

- (instancetype)initWithOperationIdentifier:(NSUInteger)tag {
	if (self = [super init]) {
		_tag = tag;
	}
	return self;
}

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
	MADOperationConditionResult *result = [self evaluateForOperation:operation];
	completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	MADOperationConditionResult *result = nil;
	NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
	if (dependencies.count == 0) {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
		return result;
	}
	
	for (MADOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
			dependency.identifier == self.tag) {
			// Through the mirror of the negative condition's factory. The old call passed
			// the dependency object where the factory expects a BOOL, so the result's own
			// `result` property was left at NO after the condition reported satisfied.
			result = [MADOperationConditionPolarQuestionAffirmativeResult newOperationCondition: (NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency
																						   name: self.name];
			break;
		}
	}

	if (result != nil) {
		return result;
	} else {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
		return result;
	}

}

@end
