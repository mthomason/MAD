//
//  MADOperationConditionPolarQuestionAffirmativeResult.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionPolarQuestionResultProtocol_h
#define MAD_Designer_MADOperationConditionPolarQuestionResultProtocol_h

#import "MADOperationConditionResult.h"

@protocol MADOperationConditionPolarQuestionResultProtocol <NSObject>

- (bool)result;

@end

@interface MADOperationConditionPolarQuestionAffirmativeResult : MADOperationConditionResult
    <MADOperationConditionPolarQuestionResultProtocol>
    @property (nonatomic, assign) bool result;

@end

@interface MADOperationConditionPolarQuestionNegativeResult : MADOperationConditionResult
    <MADOperationConditionPolarQuestionResultProtocol>
    @property (nonatomic, assign) bool result;

@end

#endif
