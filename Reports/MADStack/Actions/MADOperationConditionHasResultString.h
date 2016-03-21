//
//  MADOperationConditionHasCredientals.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionHasResultString_h
#define MAD_Designer_MADOperationConditionHasResultString_h

#import "MADOperationCondition.h"

@interface MADOperationConditionHasResultString : NSObject
    <MADOperationCondition>

    - (instancetype)initWithKey:(NSString *)key;
    @property (nonatomic, readonly, copy) NSString *key;

    - (NSString *)name;
    - (BOOL)isMutuallyExclusive;
    - (NSOperation *)dependencyForOperation:(MADOperation *)operation;
    - (void)evaluateForOperation:(MADOperation *)operation
                      completion:(void(^)(MADOperationConditionResult *))completion;

@end

#endif
