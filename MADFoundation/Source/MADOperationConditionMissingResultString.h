//
//  MADOperationConditionHasCredientals.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationConditionMissingResultString_h
#define MAD_Designer_MADOperationConditionMissingResultString_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADOperationCondition.h>

@interface MADOperationConditionMissingResultString : NSObject
    <MADOperationCondition>

    - (instancetype)initWithKey:(NSString *)key;
    @property (nonatomic, readonly, copy) NSString *key;

    - (NSString *)name;
    - (BOOL)isMutuallyExclusive;
    - (NSOperation *)dependencyForOperation:(MADOperation *)operation;
    - (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation;

@end

#endif
