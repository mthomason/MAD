//
//  MADOperationGetCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationGetCredentials.h"
#import <os/log.h>

#import <MAD/MTKeyChain.h>
#import <MAD/MADDatabaseConnection.h>

#import <MADFoundation/NSOperation+Advanced.h>
#import <MADFoundation/MADOperationQueue.h>

#import <MAD/MADOperationKeyChainGet.h>
#import "MADOperationPromptCredentials.h"
#import <MAD/MADOperationConditionMissingResultString.h>
#import <MAD/MADOperationConditionHasResultString.h>
#import "MADOperationPromptPassword.h"
#import "MADOperationPromptPolarQuestion.h"
#import "MADOperationPromptError.h"
#import "MADOperationDatabaseTestConnection.h"
#import <MAD/MADOperationKeyChainPut.h>
#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationConditionDisplayedAlert.h"
#import <MAD/MADOperationBooleanAnd.h>

static NSString * const TextSaveToKeyChain = @"Save to KeyChain";
static NSString * const TextSaveToKeyChainMessage = @"Would you like to save your username and password?";
static NSString * const TextSaveToKeyChainMessagePassword = @"Would you like to save your password?";

@interface MADOperationGetCredentials ()

    @property (nonatomic, copy) NSString *username;
    @property (nonatomic, copy) NSString *password;

    @property (nonatomic, assign) BOOL passwordSet;
    @property (nonatomic, assign) BOOL usernameSet;
    @property (nonatomic, assign) BOOL shortCircut;

@end

@implementation MADOperationGetCredentials {
    NSString *_keyUsername, *_keyPassword;
    BOOL _finishedPromptPassword;
    BOOL _finishedPromptCredentals;
}

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
                            viewController: (UIViewController *)viewController {
    if (self = [super init]) {

        _finishedPromptPassword = NO;
        _finishedPromptCredentals = NO;

        if (!(_shortCircut = ![databaseConnection requiresCredientals])) {
            [self addOperationsToGetCredentialsWithDatabaseConnection:databaseConnection
                                                       viewController:viewController];
        }

    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);
    if (_shortCircut) {
        [self finish];
    } else {
        [super execute];
    }
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    // Operation 1 & 3: Credentials in keychain.
    //  If results are read from keychain, then MADOperationResultStringProtocol.
    //---
    if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
    
        if (((NSObject <MADOperationResultStringProtocol> *) operation).success) {

            switch (((NSObject <MADOperationResultStringProtocol> *) operation).readOperationType) {
                case MADKeyChainReadOperationTypeUsername: {
                    NSString *username = ((NSObject <MADOperationResultStringProtocol> *) operation).value.copy;
                    self.username = username;
                    self.usernameSet = YES;
                    break;
                }
                
                case MADKeyChainReadOperationTypePassword: {
                    NSString *password = ((NSObject <MADOperationResultStringProtocol> *) operation).value.copy;
                    self.password = password;
                    self.passwordSet = YES;
                    break;
                }
                default:
                    break;
            }
        }
    }
    
    // Operation 2 & 4: Credentials from alert.
    //  If results are read from keychain, then MADOperationResultStringProtocol.
    //---
    if ([operation conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
        if (((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).gotCredentials) {
            NSString *username = ((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).credentials.username.copy;
            NSString *password = ((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).credentials.password.copy;
            self.username = username;
            self.usernameSet = YES;
            self.password = password;
            self.passwordSet = YES;
        }
    }
    //os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish but not calling finish?:", __PRETTY_FUNCTION__);
    //NSLog(@"Count   %d", self.internalQueue.operationCount);
    //NSLog(@"Last    %@", self.internalQueue.operations.lastObject);
    //if (self.internalQueue.operationCount == 0) {
    //    [self finish];
    //}
    
    if ([operation isKindOfClass:[MADOperationKeyChainGet class]]) {
        
    } else if ([operation isKindOfClass:[MADOperationPromptPassword class]]) {
        _finishedPromptPassword = ((MADOperationPromptPassword *)operation).alertDisplayedAffirmed;
    } else if ([operation isKindOfClass:[MADOperationPromptCredentials class]]) {
        _finishedPromptCredentals = ((MADOperationPromptCredentials *)operation).alertDisplayedAffirmed;
    }
    if (_finishedPromptPassword && _finishedPromptCredentals) {
        //[self.internalQueue cancelAllOperations];
    }
    [((MADOperation *)operation) cleanup];
}

- (MADCredential *)credentials {
    if (self.passwordSet && self.usernameSet) {
        MADCredential *credentials = [[MADCredential alloc] initWithUsername:self.username
                                                                 andPassword:self.password];
        return credentials;
    } else {
        return nil;
    }
}

- (BOOL)gotCredentials { return self.usernameSet && self.passwordSet; }

- (BOOL)completedPrompt { return _finishedPromptPassword || _finishedPromptCredentals; }

- (BOOL)manuallyInputtedCredentials { return [self gotCredentials] && [self completedPrompt]; }

- (void)addOperationsToGetCredentialsWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
                                             viewController: (UIViewController *)viewController {
    
    NSString *key = databaseConnection.connectionString;
    _keyUsername = [MTKeyChain newKeyForUsernameWithMainKey: key];
    _keyPassword = [MTKeyChain newKeyForPasswordWithMainKey: key];
    
    // Condition: Username is missing.
    MADOperationConditionMissingResultString *conditionReadUsernameFailed;
    conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey: _keyUsername];

    // Condition: Username is found.
    MADOperationConditionHasResultString *conditionReadUsername;
    conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey: _keyUsername];

    // ---------------------------------------------------
    // Operation 1: Read username.
    // -------------------------
    MADOperationKeyChainGet *getUsername;

    getUsername = [[MADOperationKeyChainGet alloc] initWithKey: _keyUsername
                                               withDescription: MTKeyChainUsernameAccountDesc];
    getUsername.readOperationType = MADKeyChainReadOperationTypeUsername;
    
    // ---------------------------------------------------
    // Operation 2: Prompt for credentials if condition is met.
    // Conditions:  Username is missing.
    // ---------------------------------------------------
    MADOperationPromptCredentials *promptCredntials;
    promptCredntials = [[MADOperationPromptCredentials alloc] initWithUsernameKey: _keyUsername
                                                                      passwordKey: _keyPassword
                                                                andViewController: viewController];
    [promptCredntials addDependency:getUsername];
    [promptCredntials addCondition:conditionReadUsernameFailed];

    // Condition: Suppressed prompt credentials
    MADOperationConditionDisplayedAlert *suppressedAlertCredntials;
    suppressedAlertCredntials = [[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:promptCredntials.identifier];
    suppressedAlertCredntials.reverseCondition = YES;
    
    // ---------------------------------------------------
    // Operation 3: Read password
    // Conditions:  Username is found.
    // ---------------------------------------------------
    MADOperationKeyChainGet *getPassword;
    getPassword = [[MADOperationKeyChainGet alloc] initWithKey: _keyPassword
                                               withDescription: MTKeyChainPasswordAccountDesc];
    getPassword.readOperationType = MADKeyChainReadOperationTypePassword;
    [getPassword addDependency:getUsername];
    [getPassword addCondition:conditionReadUsername];
    
    // Condition: Get password failed
    MADOperationConditionMissingResultString *conditionReadPasswordFailed;
    conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:_keyPassword];

    // Condition: Prompt for password only
    NSArray <NSObject <MADOperationCondition> *> *conditionsForPromptPassword;
    conditionsForPromptPassword = @[conditionReadUsername,
                                    conditionReadPasswordFailed,
                                    suppressedAlertCredntials];
    
    MADOperationBooleanAnd *conditionPromptPasswordBoolAnd;
    conditionPromptPasswordBoolAnd = [[MADOperationBooleanAnd alloc] initWithConditions:conditionsForPromptPassword];
    
    // ---------------------------------------------------
    // Operation 4: Prompt password only.
    // Conditions:  Password is missing AND
    //              Username is found AND
    //              Credentials alert was suppressed (redundant).
    // ---------------------------------------------------
    MADOperationPromptPassword *promptPassword;
    promptPassword = [[MADOperationPromptPassword alloc] initWithPasswordKey: _keyPassword
                                                           andViewController: viewController];
    [promptPassword addDependency:getUsername];
    [promptPassword addDependency:getPassword];
    [promptPassword addDependency:promptCredntials];
    [promptPassword addCondition:conditionPromptPasswordBoolAnd];
    
/*
    NSString *title = NSLocalizedString(TextSaveToKeyChain, TextSaveToKeyChain);
    NSString *messageCredntialsPrompt = NSLocalizedString(TextSaveToKeyChainMessage, TextSaveToKeyChainMessage);

    // ---------------------------------------------------
    // Operation 5a: Test the connection (credentials prompt)
    // ---------------------------------------------------
    MADOperationDatabaseTestConnection *testConnectionOperationCredentials;
    testConnectionOperationCredentials = [[MADOperationDatabaseTestConnection alloc] initWithDatabaseConnection: databaseConnection];
    [testConnectionOperationCredentials addDependency:getUsername];
    [testConnectionOperationCredentials addDependency:getPassword];
    [testConnectionOperationCredentials addDependency:promptCredntials];
    
    MADOperationConditionPolarQuestionAffirmative *promptForCredentialsAffirmative;
    promptForCredentialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:promptCredntials.identifier];
    [testConnectionOperationCredentials addCondition: promptForCredentialsAffirmative];
    
    // ---------------------------------------------------
    // Operation 5b: Test the connection (password prompt)
    // ---------------------------------------------------
    MADOperationDatabaseTestConnection *testConnectionOperationPassword;
    testConnectionOperationPassword = [[MADOperationDatabaseTestConnection alloc] initWithDatabaseConnection: databaseConnection];
    [testConnectionOperationPassword addDependency:getUsername];
    [testConnectionOperationPassword addDependency:getPassword];
    [testConnectionOperationPassword addDependency:promptPassword];
    
    MADOperationConditionPolarQuestionAffirmative *promptForPasswordAffirmative;
    promptForPasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier: promptPassword.identifier];
    [testConnectionOperationPassword addCondition: promptForPasswordAffirmative];
    
    // ---------------------------------------------------
    // Operation 5c: Display connection error if one exist
    // ---------------------------------------------------
    
    MADOperationPromptError *displayErrorCredentials;
    displayErrorCredentials = [[MADOperationPromptError alloc] initWithViewController:viewController];
    [displayErrorCredentials addDependency:testConnectionOperationCredentials];
    
    MADOperationPromptError *displayErrorPassword;
    displayErrorPassword = [[MADOperationPromptError alloc] initWithViewController:viewController];
    [displayErrorPassword addDependency:testConnectionOperationPassword];
    
    // ---------------------------------------------------
    // Operation 5d: Prompt save username and password
    // Conditions:  User entered a username and password.
    // ---------------------------------------------------
    MADOperationPromptPolarQuestion *promptSaveCredntials;
    promptSaveCredntials = [[MADOperationPromptPolarQuestion alloc] initWithTitle: title
                                                                          message: messageCredntialsPrompt
                                                                   viewController: viewController];
    [promptSaveCredntials addDependency:testConnectionOperationCredentials];
    [promptSaveCredntials addDependency:promptCredntials];
    
    [promptSaveCredntials addCondition:promptForCredentialsAffirmative];
    
    NSString *messagePasswordPrompt = NSLocalizedString(TextSaveToKeyChainMessagePassword, TextSaveToKeyChainMessagePassword);
    
    // ---------------------------------------------------
    // Operation 6: Prompt save password
    // Conditions:  User entered a password.
    // ---------------------------------------------------
    MADOperationPromptPolarQuestion *promptSavePassword;
    promptSavePassword = [[MADOperationPromptPolarQuestion alloc] initWithTitle: title
                                                                        message: messagePasswordPrompt
                                                                 viewController: viewController];
    [promptSavePassword addDependency:testConnectionOperationPassword];
    [promptSavePassword addDependency:promptPassword];
    
    [promptSavePassword addCondition:promptForPasswordAffirmative];
    
    // ---------------------------------------------------
    // Operation 7: Save username
    // Dependency:  Prompt save credentials.
    // Conditions:  User said yes to save credentials.
    // ---------------------------------------------------
    MADOperationKeyChainPut *putUsername;
    putUsername = [[MADOperationKeyChainPut alloc] initWithKey:keyUsername description:MTKeyChainUsernameAccountDesc];
    MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmative;
    promptToSaveCredntialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:promptSaveCredntials.identifier];
    [putUsername addDependency:promptCredntials];
    [putUsername addDependency:promptSaveCredntials];
    [putUsername addCondition:promptToSaveCredntialsAffirmative];
    
    // ---------------------------------------------------
    // Operation 8: Save password
    // Conditions:  User said yes to save credentials OR
    //              User said yes to save password.
    // ---------------------------------------------------
    MADOperationKeyChainPut *putPasswordCredentials;
    putPasswordCredentials = [[MADOperationKeyChainPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
    MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmativePassword;
    promptToSaveCredntialsAffirmativePassword = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:promptSaveCredntials.identifier];
    [putPasswordCredentials addDependency:promptCredntials];
    [putPasswordCredentials addDependency:promptSaveCredntials];
    [putPasswordCredentials addCondition:promptToSaveCredntialsAffirmativePassword];
    
    MADOperationKeyChainPut *putPassword = [[MADOperationKeyChainPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
    MADOperationConditionPolarQuestionAffirmative *promptToSavePasswordAffirmative;
    promptToSavePasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:promptSavePassword.identifier];
    [putPassword addDependency:promptPassword];
    [putPassword addDependency:promptSavePassword];
    [putPassword addCondition:promptToSavePasswordAffirmative];

*/
    NSArray <__kindof NSOperation *> *operations = @[getUsername, promptCredntials,
                                                     getPassword, promptPassword
                                                     //testConnectionOperationCredentials, testConnectionOperationPassword,
                                                     //displayErrorCredentials,
                                                     //displayErrorPassword,
                                                     //promptSaveCredntials,
                                                     //promptSavePassword,
                                                     //putUsername,
                                                     //putPassword
                                                     ];
    
    MADGroupOperation * __weak wself = self;
    NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
        MADGroupOperation *sself = wself;
        os_log_info(OS_LOG_DEFAULT, "%s - block", __PRETTY_FUNCTION__);
        //[sself cancel];
        //[sself finish];
        [sself finish];
        [sself cleanup];
    }];

    [self addOperations:operations finishingOperation:finishingOperation];
}

#pragma mark -
#pragma mark MADKeyChainKeyValueProtocol

- (NSString *)valueForKey:(NSString *)key {
    if ([key isEqualToString:_keyUsername]) {
        return self.credentials.username;
    } else if ([key isEqualToString:_keyPassword]) {
        return self.credentials.password;
    } else {
        return nil;
    }
}

@end
