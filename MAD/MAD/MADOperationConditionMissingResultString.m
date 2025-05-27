//
//  MADOperationConditionHasCredientals.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultStringResult.h"

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>
#import <MADFoundation/MADOperationResultStringProtocol.h>

#import <Foundation/NSOperation.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>

#import <os/log.h>

@interface MADOperationConditionMissingResultString ()
@property (nonatomic, readwrite, copy) NSString *key;
@end

@implementation MADOperationConditionMissingResultString

- (void)dealloc { }

- (instancetype)initWithKey:(NSString *)key {
	if (self = [super init]) {
		self.key = key.copy;
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
	NSArray <__kindof NSOperation *> *dependencies = operation.dependencies;
	if (dependencies.count == 0) {
		result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:NSStringFromClass(self.class)];
		return result;
	}
	
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationResultStringProtocol)] &&
			[self.key isEqualToString: ((NSObject <MADOperationResultStringProtocol> *) dependency).key]) {
			if(!((NSObject <MADOperationResultStringProtocol> *) dependency).success) {
				result = [MADOperationConditionHasResultStringResult newOperationConditionResult: YES
																						   value: ((NSObject <MADOperationResultStringProtocol> *)dependency).value
																							name: NSStringFromClass(self.class)];
				break;
			}
		}
	}
	
	if (result != nil) {
		return result;
	} else {
		result = [MADOperationConditionHasResultStringResult newOperationConditionResultFailedNotSatisfied:NSStringFromClass(self.class)];
		return result;
	}
	
}

@end
