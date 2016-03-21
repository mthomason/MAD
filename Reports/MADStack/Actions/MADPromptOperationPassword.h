//
//  MADPromptPasswordOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADPromptOperationPassword_h
#define MAD_Designer_MADPromptOperationPassword_h

#import "MADOperation.h"
#import <UIKit/UIViewController.h>
#import <MAD/MADCredential.h>
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionDisplayedAlert.h"

@interface MADPromptOperationPassword : MADOperation
    <MADOperationHoldsCredentialsProtocol, MADOperationHoldsPasswordProtocol,
        MADOperationConditionPolarQuestionResultProtocol,
        MADOperationConditionDisplayedAlertProtocol>

    - (instancetype)initWithViewController:(UIViewController *)viewController;

    @property (nonatomic, readonly, copy) MADCredential *credentials;
    @property (nonatomic, readonly, assign) bool gotCredentials;

    @property (nonatomic, readonly, assign) bool alertDisplayed;

    @property (nonatomic, readonly, copy) NSString *password;
    @property (nonatomic, readonly, assign) bool gotPassword;

    @property (nonatomic, readonly, assign) MADCredentialSource source;

    @property (nonatomic, readonly, assign) bool bypass;
    @property (nonatomic, readonly, assign) bool userContinue;

    @property (nonatomic, assign) bool result;

@end

#endif
