//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionPolarQuestionNegative.h"
#import <os/log.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>
#import "MADOperationPromptPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"

@interface MADOperationConditionPolarQuestionNegative ()

    @property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionPolarQuestionNegative

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

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
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}


- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    os_log_info(OS_LOG_DEFAULT, "Evaluate\t%s", operation.description.UTF8String);

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
