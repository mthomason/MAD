//
//  MADOperationBooleanAnd.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/21/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationBooleanAnd.h"
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <os/log.h>

@interface MADOperationBooleanAnd ()

    @property (nonatomic, copy) NSArray <NSObject <MADOperationCondition> *> *conditions;

@end

@implementation MADOperationBooleanAnd

- (void)dealloc { }

- (instancetype)initWithConditions:(NSArray <NSObject <MADOperationCondition> *> *)conditions {
	if (self = [super init]) {
		_conditions = conditions.copy;
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
	BOOL succes = YES;
	for (NSObject <MADOperationCondition> *condition in self.conditions) {
		MADOperationConditionResult *result = [condition evaluateForOperation:operation];
		if (!result.isSucceed) {
			succes = NO;
			break;
		}
	}
	return [MADOperationConditionResult newOperationConditionResult: succes name: NSStringFromClass(self.class)];
}

@end
