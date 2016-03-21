//
//  MADOperationConditionPolarQuestionAffirmative.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionPolarQuestionNegative_h
#define MAD_Designer_MADOperationConditionPolarQuestionNegative_h

#import "MADOperationCondition.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"

@interface MADOperationConditionPolarQuestionNegative : NSObject
    <MADOperationCondition>

    - (instancetype)initWithTag:(NSUInteger)tag;

@end

#endif
