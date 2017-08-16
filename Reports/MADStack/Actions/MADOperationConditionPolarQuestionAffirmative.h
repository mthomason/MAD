//
//  MADOperationConditionPolarQuestionAffirmative.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionPolarQuestionAffirmative_h
#define MAD_Designer_MADOperationConditionPolarQuestionAffirmative_h

#import <MADFoundation/MADOperationCondition.h>
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"

@interface MADOperationConditionPolarQuestionAffirmative : NSObject
    <MADOperationCondition>

    - (instancetype)initWithOperationIdentifier:(NSUInteger)tag;

@end

#endif
