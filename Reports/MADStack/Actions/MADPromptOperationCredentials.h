//
//  MADPromptOperationCredentials.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADPromptOperationCredentials_h
#define MAD_Designer_MADPromptOperationCredentials_h

#import "MADOperation.h"
#import <MAD/MADCredential.h>
#import "MADOperationConditionDisplayedAlert.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADKeyChainOperationPut.h"

@class UIViewController;

@interface MADPromptOperationCredentials : MADOperation
    <MADOperationConditionPolarQuestionResultProtocol, MADKeyChainKeyValueProtocol,
        MADOperationHoldsCredentialsProtocol, MADOperationConditionDisplayedAlertProtocol>

    - (instancetype)initWithUsernameKey:(NSString *)usernameKey passwordKey:(NSString *)passwordKey
                                                          andViewController:(UIViewController *)viewController;
    - (NSString *)valueForKey:(NSString *)key;

    @property (nonatomic, readonly, assign) bool alertDisplayed;

    @property (nonatomic, readonly, copy) MADCredential *credentials;
    @property (nonatomic, readonly, assign) bool gotCredentials;

    @property (nonatomic, readonly, assign) MADCredentialSource source;

    @property (nonatomic, readonly, assign) bool bypass;
    @property (nonatomic, readonly, assign) bool userContinue;
    @property (nonatomic, readonly, assign) bool displayingPrompt;
    @property (nonatomic, readonly, assign) bool result;

@end

#endif
