//
//  MADOperationConditionPolarQuestionAffirmativeResult.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionResult.h"

@protocol MADOperationConditionPolarQuestionAffirmativeResultProtocol <NSObject>

- (bool)result;

@end

@interface MADOperationConditionPolarQuestionAffirmativeResult : MADOperationConditionResult
    <MADOperationConditionPolarQuestionAffirmativeResultProtocol>

    @property (nonatomic, assign) bool result;

@end
