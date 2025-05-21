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
#import "madlog.h"

#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>

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
	os_log_info(GetDesignerLog(), "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);
	MADOperationConditionResult *result;
	result = [self evaluateForOperation:operation];
	completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
	os_log_info(GetDesignerLog(), "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);

	MADOperationConditionResult *result = nil;
	NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
	if (dependencies.count == 0) {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
		return result;
	}
	
	for (MADOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
			dependency.identifier == self.tag) {
			if (((NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency).result) {
				result = [MADOperationConditionPolarQuestionAffirmativeResult newOperationConditionResult: dependency
																									 name: self.name];
			}
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
