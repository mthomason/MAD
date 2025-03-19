//
//  MADOperationConditionPolarQuestionAffirmative.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionPolarQuestionNegative_h
#define MAD_Designer_MADOperationConditionPolarQuestionNegative_h

#import <MADFoundation/MADOperationCondition.h>
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"

@interface MADOperationConditionPolarQuestionNegative : NSObject
	<MADOperationCondition>

	- (instancetype)initWithOperationIdentifier:(NSUInteger)tag;

@end

#endif
