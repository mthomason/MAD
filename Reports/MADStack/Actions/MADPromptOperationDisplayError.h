//
//  MADPromptOperationDisplayError.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADPromptOperationDisplayError_h
#define MAD_Designer_MADPromptOperationDisplayError_h

#import "MADOperation.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionDisplayedAlert.h"

@class UIViewController;

@protocol MADPromptOperationDisplayErrorProtocol <NSObject>

    - (NSError *)error;
    - (bool)displayError;
    - (NSUInteger)tag;

@end

@interface MADPromptOperationDisplayError : MADOperation
    <MADOperationConditionPolarQuestionResultProtocol, MADOperationConditionDisplayedAlertProtocol>
    
    - (instancetype)initWithViewController:(UIViewController * __weak)viewController;

    - (instancetype)initWithDependencyTag:(NSUInteger)dependencyTag
                           viewController:(UIViewController * __weak)viewController;

    - (instancetype)initWithError:(NSError *)error
                   viewController:(UIViewController * __weak)viewController;

    @property (nonatomic, readonly, assign) bool alertDisplayed;
    @property (nonatomic, readonly, assign) bool result;
    @property (nonatomic, assign) NSUInteger tagDependency;   // If zero, then first one found is displayed.

@end

#endif
