//
//  MADOperationConditionPolarQuestionAffirmativeResult.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationConditionPolarQuestionResultProtocol_h
#define MAD_Designer_MADOperationConditionPolarQuestionResultProtocol_h

#import <MADFoundation/MADOperationConditionResult.h>

@protocol MADOperationConditionPolarQuestionResultProtocol <NSObject>
	- (BOOL)result;
@end


@interface MADOperationConditionPolarQuestionAffirmativeResult : MADOperationConditionResult
	<MADOperationConditionPolarQuestionResultProtocol>
	@property (nonatomic, assign) BOOL result;

	+ (instancetype)newOperationCondition:(NSObject <MADOperationConditionPolarQuestionResultProtocol> *)delegate
									 name:(NSString *)name;

@end

@interface MADOperationConditionPolarQuestionNegativeResult : MADOperationConditionResult
	<MADOperationConditionPolarQuestionResultProtocol>
	@property (nonatomic, assign) BOOL result;

	+ (instancetype)newOperationCondition:(NSObject <MADOperationConditionPolarQuestionResultProtocol> *)delegate
									 name:(NSString *)name;

@end

#endif
