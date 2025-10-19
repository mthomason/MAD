//
//  MADOperationPromptPolarQuestion.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationPromptPolarQuestion_h
#define MAD_Designer_MADOperationPromptPolarQuestion_h

#import <MADFoundation/MADOperation.h>
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionDisplayedAlert.h"

@class UIViewController;

@interface MADOperationPromptPolarQuestion : MADOperation
	<MADOperationConditionPolarQuestionResultProtocol, MADOperationConditionDisplayedAlertProtocol>
	
	- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message
				   viewController:(UIViewController * __weak)viewController;

	@property (nonatomic, readonly, assign) BOOL alertDisplayed;
	@property (nonatomic, readonly, assign) BOOL result;

@end

#endif
