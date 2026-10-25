//
//  MADOperationConditionHasCredientals.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationConditionHasResultString_h
#define MAD_Designer_MADOperationConditionHasResultString_h

#import <MADFoundation/MADOperationCondition.h>

@interface MADOperationConditionHasResultString : NSObject <MADOperationCondition>

@property (nonatomic, readonly, copy) NSString *key;

- (instancetype)initWithKey:(NSString *)key NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;
- (NSString *)name;
- (BOOL)isMutuallyExclusive;
- (NSOperation *)dependencyForOperation:(MADOperation *)operation;
- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation;

@end

#endif
