//
//  MADOperationConditionHasCredientialsResult.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionHasResultStringResult_h
#define MAD_Designer_MADOperationConditionHasResultStringResult_h

#import "MADOperationConditionResult.h"

@class MADCredential;

@interface MADOperationConditionHasResultStringResult : MADOperationConditionResult

    @property (nonatomic, copy) NSString *result;

@end

#endif
