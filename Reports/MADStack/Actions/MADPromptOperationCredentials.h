//
//  MADPromptOperationCredentials.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADPromptOperationCredentials_h
#define MAD_Designer_MADPromptOperationCredentials_h

#import "MADOperation.h"
#import <MAD/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
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

    @property (nonatomic, readonly, assign) BOOL alertDisplayed;
    @property (nonatomic, readonly, assign) BOOL alertDisplayedAffirmed;

    @property (nonatomic, readonly, copy) MADCredential *credentials;
    @property (nonatomic, readonly, assign) BOOL gotCredentials;

    @property (nonatomic, readonly, assign) MADCredentialSource source;

    @property (nonatomic, readonly, assign) BOOL bypass;
    @property (nonatomic, readonly, assign) BOOL userContinue;
    @property (nonatomic, readonly, assign) BOOL displayingPrompt;
    @property (nonatomic, readonly, assign) BOOL result;

@end

#endif
