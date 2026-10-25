//
//  MADOperationPromptCredentials.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationPromptCredentials_h
#define MAD_Designer_MADOperationPromptCredentials_h

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADOperationKeyChainPut.h>
#import "MADOperationConditionDisplayedAlert.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"

@class UIViewController;

@interface MADOperationPromptCredentials : MADOperation <MADOperationConditionPolarQuestionResultProtocol, MADKeyChainKeyValueProtocol, MADOperationHoldsCredentialsProtocol, MADOperationConditionDisplayedAlertProtocol>

- (instancetype)initWithUsernameKey:(NSString *)usernameKey
						passwordKey:(NSString *)passwordKey
				  andViewController:(UIViewController *)viewController;
- (NSString *)valueForKey:(NSString *)key;

@property (nonatomic, readonly, assign) BOOL alertDisplayed;
@property (nonatomic, readonly, assign) BOOL alertDisplayedAffirmed;
@property (nonatomic, readonly, assign) BOOL gotCredentials;
@property (nonatomic, readonly, assign) BOOL bypass;
@property (nonatomic, readonly, assign) BOOL userContinue;
@property (nonatomic, readonly, assign) BOOL displayingPrompt;
@property (nonatomic, readonly, assign) BOOL result;

@property (nonatomic, readonly, assign) MADCredentialSource source;

@property (nonatomic, readonly, copy) MADCredential *credentials;

@end

#endif
