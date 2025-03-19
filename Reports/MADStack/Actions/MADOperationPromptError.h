//
//  MADOperationPromptError.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationPromptError_h
#define MAD_Designer_MADOperationPromptError_h

#import <MADFoundation/MADOperation.h>
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionDisplayedAlert.h"

@class UIViewController;

@interface MADOperationPromptError : MADOperation
	<MADOperationConditionPolarQuestionResultProtocol, MADOperationConditionDisplayedAlertProtocol>
	
	- (instancetype)initWithViewController:(UIViewController * __weak)viewController;

	- (instancetype)initWithDependencyTag:(NSUInteger)dependencyTag
						   viewController:(UIViewController * __weak)viewController;

	- (instancetype)initWithError:(NSError *)error
				   viewController:(UIViewController * __weak)viewController;

	@property (nonatomic, readonly, assign) BOOL alertDisplayed;
	@property (nonatomic, readonly, assign) BOOL result;
	@property (nonatomic, assign) NSUInteger tagDependency;   // If zero, then first one found is displayed.

@end

#endif
