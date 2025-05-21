//
//  MADOperationConditionResult.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionResult_h
#define MAD_Designer_MADOperationConditionResult_h

#import <MADFoundation/MADOperationCondition.h>
#import <Foundation/NSObject.h>

@class MADOperation, MADOperationCondition;

extern NSString * _Nonnull const MADOperationConditionKey;

@interface MADOperationConditionResult : NSObject

@property (nonatomic, readonly) BOOL isSucceed;
@property (nonatomic, readonly, nullable) NSError *error;

+ (nonnull instancetype)newOperationConditionResultSatisfied;
+ (nonnull instancetype)newOperationConditionResult:(BOOL)satisfied;
+ (nonnull instancetype)newOperationConditionResult:(BOOL)satisfied
											   name:(nonnull NSString *)name;
+ (nonnull instancetype)newOperationConditionResultFailedNotSatisfied:(nonnull NSString *)name;
+ (nonnull instancetype)newOperationConditionResultFailed:(nonnull NSError *)error;
+ (void)evaluateConditions:(nonnull NSArray<id<MADOperationCondition>> *)conditions
				 operation:(nonnull MADOperation *)operation
				completion:(nonnull void(^)(NSArray<NSError *> * _Nonnull errors))completion;

@end

#endif
