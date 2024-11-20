//
//  MADOperationConditionHasResultStringResult.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationConditionHasResultStringResult.h"
#import <Foundation/NSString.h>
#import <MADFoundation/MADOperationResultStringProtocol.h>

@implementation MADOperationConditionHasResultStringResult

+ (instancetype)newOperationConditionResult:(BOOL)satisfied
                                      value:(NSString *)value
                                       name:(NSString *)name {
    id operationCondition;
    if (satisfied) {
        operationCondition = [self newOperationConditionResultSatisfied];
        ((MADOperationConditionHasResultStringResult *)operationCondition).result = value.copy;
    } else {
        operationCondition = [self newOperationConditionResultFailedNotSatisfied:name];
    }
    return operationCondition;
}

+ (instancetype)newOperationCondition:(NSObject <MADOperationResultStringProtocol> *)delegate
                                 name:(NSString *)name {
    id operationCondition;
    if (delegate.success) {
        operationCondition = [self newOperationConditionResultSatisfied];
        ((MADOperationConditionHasResultStringResult *)operationCondition).result = delegate.value.copy;
    } else {
        operationCondition = [self newOperationConditionResultFailedNotSatisfied:name];
    }
    return operationCondition;
}

@end
