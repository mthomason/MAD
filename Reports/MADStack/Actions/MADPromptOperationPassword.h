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
#import <MAD/MADCredentialSourceType.h>
#import <MAD/MADOperationHoldsPasswordProtocol.h>
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionDisplayedAlert.h"
#import "MADKeyChainOperationGet.h"
#import "MADKeyChainOperationPut.h"


@interface MADPromptOperationPassword : MADOperation
    <MADOperationResultStringProtocol,
        MADKeyChainKeyValueProtocol,
        MADOperationHoldsPasswordProtocol,
        MADOperationConditionPolarQuestionResultProtocol,
        MADOperationConditionDisplayedAlertProtocol>

    - (instancetype)initWithPasswordKey:(NSString *)passwordKey andViewController:(UIViewController *)viewController;
    - (NSString *)valueForKey:(NSString *)key;

    @property (nonatomic, readonly, assign) BOOL alertDisplayed;
    @property (nonatomic, readonly, assign) BOOL gotPassword;
    @property (nonatomic, readonly, assign) BOOL bypass;
    @property (nonatomic, readonly, assign) BOOL userContinue;
    @property (nonatomic, assign) BOOL result;

    @property (nonatomic, readonly, assign) MADCredentialSource source;

    @property (nonatomic, readonly, copy) NSString *password;

@end

#endif
