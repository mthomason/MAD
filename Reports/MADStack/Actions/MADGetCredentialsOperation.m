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
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
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

- (instancetype)initWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection viewController: (UIViewController *)viewController {
    if (self = [super init]) {

        //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
        if (!(_shortCircut = ![databaseConnection requiresCredientals])) {
            [self addOperationsToGetCredentialsWithDatabaseConnection:databaseConnection viewController:viewController];
        }

    }
    return self;
}

- (void)execute {
    
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Execute:", __PRETTY_FUNCTION__);
    if (_shortCircut) {
        [self finish];
    } else {
        [super execute];
    }
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Did finsih:", __PRETTY_FUNCTION__);
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
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish but not calling finish?:", __PRETTY_FUNCTION__);
    //NSLog(@"Count   %d", self.internalQueue.operationCount);
    //NSLog(@"Last    %@", self.internalQueue.operations.lastObject);
    //if (self.internalQueue.operationCount == 0) {
    //    [self finish];
    //}
}

// Helper functions

- (void)addOperationsToGetCredentialsWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
                                             viewController: (UIViewController *)viewController {
    
    NSString *key = databaseConnection.connectionString;
    NSString *keyUsername = [MTKeyChain newKeyForUsernameWithMainKey: key];
    NSString *keyPassword = [MTKeyChain newKeyForPasswordWithMainKey: key];
    
    // ---------------------------------------------------
    // Operation 1: Read username.
    // -------------------------
    MADKeyChainOperationGet *getUsername = [[MADKeyChainOperationGet alloc] initWithKey:keyUsername withDescription:MTKeyChainUsernameAccountDesc];
    getUsername.readOperationType = MADKeyChainReadOperationTypeUsername;
    
    // ---------------------------------------------------
    // Operation 2: Prompt for credentials if condition is met.
    // Conditions:  Username is missing.
    // ---------------------------------------------------
    MADPromptOperationCredentials *promptCredntials = [[MADPromptOperationCredentials alloc] initWithUsernameKey: keyUsername passwordKey: keyPassword
                                                                                               andViewController: viewController];
    [promptCredntials addDependency:getUsername];
    
    // Condition: Username is missing.
    MADOperationConditionMissingResultString *conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyUsername];
    [promptCredntials addCondition:conditionReadUsernameFailed];
    
    
    // ---------------------------------------------------
    // Operation 3: Read password
    // Conditions:  Username is found.
    // ---------------------------------------------------
    MADKeyChainOperationGet *getPassword = [[MADKeyChainOperationGet alloc] initWithKey: keyPassword
                                                                        withDescription: MTKeyChainPasswordAccountDesc];
    getPassword.readOperationType = MADKeyChainReadOperationTypePassword;
    [getPassword addDependency:getUsername];
    
    // Condition: Username is found.
    MADOperationConditionHasResultString *conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey:keyUsername];
    [getPassword addCondition:conditionReadUsername];
    
    
    // ---------------------------------------------------
    // Operation 4: Prompt password only.
    // Conditions:  Password is missing AND
    //              Username is found AND
    //              Credentials alert was suppressed (redundant).
    // ---------------------------------------------------
    MADPromptOperationPassword *promptPassword = [[MADPromptOperationPassword alloc] initWithPasswordKey:keyPassword andViewController:viewController];
    [promptPassword addDependency:getUsername];
    [promptPassword addDependency:getPassword];
    [promptPassword addDependency:promptCredntials];
    
    MADOperationConditionDisplayedAlert *suppressedAlertCredntials = [[MADOperationConditionDisplayedAlert alloc] initWithTag:promptCredntials.hash];
    suppressedAlertCredntials.reverseCondition = YES;
    
    MADOperationConditionMissingResultString *conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyPassword];
    
    NSArray <NSObject <MADOperationCondition> *> *conditionsForPromptPassword = @[conditionReadUsername, conditionReadPasswordFailed, suppressedAlertCredntials];
    
    MADOperationBooleanAnd *conditionPromptPasswordBoolAnd = [[MADOperationBooleanAnd alloc] initWithConditions:conditionsForPromptPassword];
    [promptPassword addCondition:conditionPromptPasswordBoolAnd];
    
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
    promptForCredentialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptCredntials.hash];
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
    promptForPasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptPassword.hash];
    [testConnectionOperationPassword addCondition: promptForPasswordAffirmative];
    
    // ---------------------------------------------------
    // Operation 5c: Display connection error if one exist
    // ---------------------------------------------------
    
    MADPromptOperationDisplayError *displayErrorCredentials = [[MADPromptOperationDisplayError alloc] initWithViewController:viewController];
    [displayErrorCredentials addDependency:testConnectionOperationCredentials];
    
    MADPromptOperationDisplayError *displayErrorPassword = [[MADPromptOperationDisplayError alloc] initWithViewController:viewController];
    [displayErrorPassword addDependency:testConnectionOperationPassword];
    
    // ---------------------------------------------------
    // Operation 5d: Prompt save username and password
    // Conditions:  User entered a username and password.
    // ---------------------------------------------------
    MADPromptOperationPolarQuestion *promptSaveCredntials = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title message:messageCredntialsPrompt viewController:viewController];
    [promptSaveCredntials addDependency:testConnectionOperationCredentials];
    [promptSaveCredntials addDependency:promptCredntials];
    
    [promptSaveCredntials addCondition:promptForCredentialsAffirmative];
    
    NSString *messagePasswordPrompt = NSLocalizedString(TextSaveToKeyChainMessagePassword, TextSaveToKeyChainMessagePassword);
    
    // ---------------------------------------------------
    // Operation 6: Prompt save password
    // Conditions:  User entered a password.
    // ---------------------------------------------------
    MADPromptOperationPolarQuestion *promptSavePassword;
    promptSavePassword = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title message:messagePasswordPrompt viewController:viewController];
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
    promptToSaveCredntialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSaveCredntials.hash];
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
    promptToSaveCredntialsAffirmativePassword = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSaveCredntials.hash];
    [putPasswordCredentials addDependency:promptCredntials];
    [putPasswordCredentials addDependency:promptSaveCredntials];
    [putPasswordCredentials addCondition:promptToSaveCredntialsAffirmativePassword];
    
    MADKeyChainOperationPut *putPassword = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
    MADOperationConditionPolarQuestionAffirmative *promptToSavePasswordAffirmative;
    promptToSavePasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSavePassword.hash];
    [putPassword addDependency:promptPassword];
    [putPassword addDependency:promptSavePassword];
    [putPassword addCondition:promptToSavePasswordAffirmative];
    
    // Operation: Confirm Save Username and Password
    NSArray <__kindof NSOperation *> *operations = @[getUsername, promptCredntials,
                                                     getPassword, promptPassword,
                                                     testConnectionOperationCredentials, testConnectionOperationPassword,
                                                     displayErrorCredentials, displayErrorPassword,
                                                     promptSaveCredntials, promptSavePassword,
                                                     putUsername, putPassword];
    
    MADGroupOperation * __weak wself = self;
    NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
        MADGroupOperation *sself = wself;
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish:", __PRETTY_FUNCTION__);
        [sself finish];
    }];

    [self addOperations:operations finishingOperation:finishingOperation];
}

@end
