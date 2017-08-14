//
//  MADGetCredentialsOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADGetCredentialsOperation.h"
#import <MAD/MTKeyChain.h>
#import <MAD/MADDatabaseConnection.h>
#import "NSOperation+Advanced.h"
#import "MADOperationQueue.h"
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultString.h"
#import "MADPromptOperationPassword.h"
#import "MADPromptOperationPolarQuestion.h"
#import "MADPromptOperationDisplayError.h"
#import "MADOperationDatabaseTestConnection.h"
#import "MADKeyChainOperationPut.h"
#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationConditionDisplayedAlert.h"
#import "MADOperationBooleanAnd.h"
#import "MADDefer.h"

#import <os/log.h>

static NSString * const TextSaveToKeyChain = @"Save to KeyChain";
static NSString * const TextSaveToKeyChainMessage = @"Would you like to save your username and password?";
static NSString * const TextSaveToKeyChainMessagePassword = @"Would you like to save your password?";

@interface MADGetCredentialsOperation ()

    @property (nonatomic, copy) NSString *username;
    @property (nonatomic, copy) NSString *password;
    @property (nonatomic, assign) BOOL passwordSet;
    @property (nonatomic, assign) BOOL usernameSet;

    @property (nonatomic, assign) BOOL shortCircut;

@end

@implementation MADGetCredentialsOperation

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
                            viewController: (UIViewController *)viewController {
    if (self = [super init]) {

        //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
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
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
    if (_shortCircut) {
        [self finish];
    } else {
        [super execute];
    }
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);
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
    if (self.internalQueue.operationCount == 0) {
        [self finish];
    }
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

- (void)addOperationsToGetCredentialsWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
                                             viewController: (UIViewController *)viewController {
    
    NSString *key = databaseConnection.connectionString;
    NSString *keyUsername = [MTKeyChain newKeyForUsernameWithMainKey: key];
    NSString *keyPassword = [MTKeyChain newKeyForPasswordWithMainKey: key];
    
    // ---------------------------------------------------
    // Operation 1: Read username.
    // -------------------------
    MADKeyChainOperationGet *getUsername;

    getUsername = [[MADKeyChainOperationGet alloc] initWithKey: keyUsername
                                               withDescription: MTKeyChainUsernameAccountDesc];
    getUsername.readOperationType = MADKeyChainReadOperationTypeUsername;
    
    // Condition: Username is missing.
    MADOperationConditionMissingResultString *conditionReadUsernameFailed;
    conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyUsername];
    
    // Condition: Username is found.
    MADOperationConditionHasResultString *conditionReadUsername;
    conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey:keyUsername];

    
    // ---------------------------------------------------
    // Operation 2: Prompt for credentials if condition is met.
    // Conditions:  Username is missing.
    // ---------------------------------------------------
    MADPromptOperationCredentials *promptCredntials;
    promptCredntials = [[MADPromptOperationCredentials alloc] initWithUsernameKey: keyUsername
                                                                      passwordKey: keyPassword
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
    MADKeyChainOperationGet *getPassword;
    getPassword = [[MADKeyChainOperationGet alloc] initWithKey: keyPassword
                                               withDescription: MTKeyChainPasswordAccountDesc];
    getPassword.readOperationType = MADKeyChainReadOperationTypePassword;
    [getPassword addDependency:getUsername];
    [getPassword addCondition:conditionReadUsername];
    
    // Condition: Get password failed
    MADOperationConditionMissingResultString *conditionReadPasswordFailed;
    conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyPassword];

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
    MADPromptOperationPassword *promptPassword;
    promptPassword = [[MADPromptOperationPassword alloc] initWithPasswordKey: keyPassword
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
    
    MADPromptOperationDisplayError *displayErrorCredentials;
    displayErrorCredentials = [[MADPromptOperationDisplayError alloc] initWithViewController:viewController];
    [displayErrorCredentials addDependency:testConnectionOperationCredentials];
    
    MADPromptOperationDisplayError *displayErrorPassword;
    displayErrorPassword = [[MADPromptOperationDisplayError alloc] initWithViewController:viewController];
    [displayErrorPassword addDependency:testConnectionOperationPassword];
    
    // ---------------------------------------------------
    // Operation 5d: Prompt save username and password
    // Conditions:  User entered a username and password.
    // ---------------------------------------------------
    MADPromptOperationPolarQuestion *promptSaveCredntials;
    promptSaveCredntials = [[MADPromptOperationPolarQuestion alloc] initWithTitle: title
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
    MADPromptOperationPolarQuestion *promptSavePassword;
    promptSavePassword = [[MADPromptOperationPolarQuestion alloc] initWithTitle: title
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
    MADKeyChainOperationPut *putUsername;
    putUsername = [[MADKeyChainOperationPut alloc] initWithKey:keyUsername description:MTKeyChainUsernameAccountDesc];
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
    MADKeyChainOperationPut *putPasswordCredentials;
    putPasswordCredentials = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
    MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmativePassword;
    promptToSaveCredntialsAffirmativePassword = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:promptSaveCredntials.identifier];
    [putPasswordCredentials addDependency:promptCredntials];
    [putPasswordCredentials addDependency:promptSaveCredntials];
    [putPasswordCredentials addCondition:promptToSaveCredntialsAffirmativePassword];
    
    MADKeyChainOperationPut *putPassword = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
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
        [sself finish];
    }];

    [self addOperations:operations finishingOperation:finishingOperation];
}

@end
