//
//  MADOperationConditionHasCredientialsResult.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionHasCredientialsResult_h
#define MAD_Designer_MADOperationConditionHasCredientialsResult_h

#import "MADOperationConditionResult.h"

@class MADCredential;

@interface MADOperationConditionHasCredientialsResult : MADOperationConditionResult

@property (nonatomic, copy) MADCredential *credential;

@end

#endif
