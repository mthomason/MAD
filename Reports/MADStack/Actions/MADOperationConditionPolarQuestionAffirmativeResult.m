//
//  MADOperationConditionPolarQuestionAffirmativeResult.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import <Foundation/NSString.h>
#import "MADOperationResultStringProtocol.h"

@implementation MADOperationConditionPolarQuestionAffirmativeResult

+ (instancetype)newOperationCondition:(NSObject <MADOperationConditionPolarQuestionResultProtocol> *)delegate
                                 name:(NSString *)name {
    id operationCondition;
    if (delegate.result) {
        operationCondition = [self newOperationConditionResultSatisfied];
        ((MADOperationConditionPolarQuestionAffirmativeResult *)operationCondition).result = YES;
    } else {
        operationCondition = [self newOperationConditionResultFailedNotSatisfied:name];
    }
    return operationCondition;
}

@end

@implementation MADOperationConditionPolarQuestionNegativeResult

+ (instancetype)newOperationCondition:(NSObject <MADOperationConditionPolarQuestionResultProtocol> *)delegate
                                 name:(NSString *)name {
    id operationCondition;
    if (!delegate.result) {
        operationCondition = [self newOperationConditionResultSatisfied];
        ((MADOperationConditionPolarQuestionNegativeResult *)operationCondition).result = YES;
    } else {
        operationCondition = [self newOperationConditionResultFailedNotSatisfied:name];
    }
    return operationCondition;
}

@end
