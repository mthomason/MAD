//
//  MADPromptOperationPolarQuestion.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADPromptOperationPolarQuestion_h
#define MAD_Designer_MADPromptOperationPolarQuestion_h

#import "MADOperation.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"

@class UIViewController;

@interface MADPromptOperationPolarQuestion : MADOperation
    <MADOperationConditionPolarQuestionAffirmativeResultProtocol>
    
    - (instancetype)initWithTitle:(NSString *)title message:(NSString *)message
                   viewController:(UIViewController * __weak)viewController;

    @property (nonatomic, readonly, assign) bool result;

@end

#endif
