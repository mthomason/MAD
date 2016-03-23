//
//  MADGetCredentialsOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADGetCredentialsOperation.h"
#import "NSOperation+Advanced.h"
#import <MAD/MTKeyChain.h>
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultString.h"
#import "MADPromptOperationPassword.h"
#import "MADPromptOperationPolarQuestion.h"
#import "MADOperationQueue.h"
#import "MADKeyChainOperationPut.h"
#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationConditionDisplayedAlert.h"
#import "MADOperationBooleanAnd.h"

static NSString * const TextSaveToKeyChain = @"Save to KeyChain";
static NSString * const TextSaveToKeyChainMessage = @"Would you like to save your username and password?";
static NSString * const TextSaveToKeyChainMessagePassword = @"Would you like to save your password?";

@interface MADGetCredentialsOperation ()

    @property (nonatomic, copy) NSString *username;
    @property (nonatomic, copy) NSString *password;
    @property (nonatomic, assign) bool passwordSet;
    @property (nonatomic, assign) bool usernameSet;

@end

@implementation MADGetCredentialsOperation

- (MADCredential *)credentials {
    if (self.passwordSet && self.usernameSet) {
        MADCredential *credentials = [[MADCredential alloc] initWithUsername:self.username andPassword:self.password];
        return credentials;
    } else {
        return nil;
    }
}

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController {
    
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    
    // ---------------------------------------------------
    // Operation 1: Read username.
    // -------------------------
    MADKeyChainOperationGet *getUsername = [[MADKeyChainOperationGet alloc] initWithKey:keyUsername];
    getUsername.readOperationType = username;
    
    // ---------------------------------------------------
    // Operation 2: Prompt for credentials if condition is met.
    // Conditions:  Username is missing.
    // ---------------------------------------------------
    MADPromptOperationCredentials *promptCredntials = [[MADPromptOperationCredentials alloc] initWithViewController:viewController];
    [promptCredntials addDependency:getUsername];
    
    // Condition: Username is missing.
    MADOperationConditionMissingResultString *conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyUsername];
    [promptCredntials addCondition:conditionReadUsernameFailed];
    
    
    
    // ---------------------------------------------------
    // Operation 3: Read password
    // Conditions:  Username is found.
    // ---------------------------------------------------
    MADKeyChainOperationGet *getPassword = [[MADKeyChainOperationGet alloc] initWithKey:keyPassword];
    getPassword.readOperationType = password;
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
    MADPromptOperationPassword *promptPassword = [[MADPromptOperationPassword alloc] initWithViewController:viewController];
    [promptPassword addDependency:getUsername];
    [promptPassword addDependency:getPassword];
    [promptPassword addDependency:promptCredntials];
    
    MADOperationConditionDisplayedAlert *suppressedAlertCredntials = [[MADOperationConditionDisplayedAlert alloc] initWithTag:promptCredntials.hash];
    suppressedAlertCredntials.reverseCondition = true;

    MADOperationConditionMissingResultString *conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyPassword];

    NSArray <NSObject <MADOperationCondition> *> *conditionsForPromptPassword = @[conditionReadUsername, conditionReadPasswordFailed, suppressedAlertCredntials];

    MADOperationBooleanAnd *conditionPromptPasswordBoolAnd = [[MADOperationBooleanAnd alloc] initWithConditions:conditionsForPromptPassword];
    [promptPassword addCondition:conditionPromptPasswordBoolAnd];

    NSString *title = NSLocalizedString(TextSaveToKeyChain, TextSaveToKeyChain);
    NSString *message = NSLocalizedString(TextSaveToKeyChainMessagePassword, TextSaveToKeyChainMessagePassword);


    // ---------------------------------------------------
    // Operation 5: Prompt save username and password
    // Conditions:  User entered a username and password.
    // ---------------------------------------------------
    MADPromptOperationPolarQuestion *promptSaveCredntials = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title message:message viewController:viewController];
    [promptSaveCredntials addDependency:promptCredntials];
    
    MADOperationConditionPolarQuestionAffirmative *promptForCredentialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptCredntials.hash];
    [promptSaveCredntials addCondition:promptForCredentialsAffirmative];

    
    // ---------------------------------------------------
    // Operation 6: Prompt save password
    // Conditions:  User entered a password.
    // ---------------------------------------------------
    MADPromptOperationPolarQuestion *promptSavePassword = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title message:message viewController:viewController];
    [promptSavePassword addDependency:promptPassword];

    MADOperationConditionPolarQuestionAffirmative *promptForPasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptPassword.hash];
    [promptSavePassword addCondition:promptForPasswordAffirmative];

    // ---------------------------------------------------
    // Operation 7: Save username
    // Dependency:  Prompt save credentials.
    // Conditions:  User said yes to save credentials.
    // ---------------------------------------------------
    MADKeyChainOperationPut *putUsername = [[MADKeyChainOperationPut alloc] initWithKey:keyUsername];
    MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSaveCredntials.hash];
    [putUsername addDependency:promptSaveCredntials];
    [putUsername addCondition:promptToSaveCredntialsAffirmative];

    
    // ---------------------------------------------------
    // Operation 8: Save password
    // Conditions:  User said yes to save credentials OR
    //              User said yes to save password.
    // ---------------------------------------------------
    MADKeyChainOperationPut *putPassword = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword];
    MADOperationConditionPolarQuestionAffirmative *promptToSavePasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSavePassword.hash];
    [putPassword addCondition:promptToSaveCredntialsAffirmative];
    [putPassword addCondition:promptToSavePasswordAffirmative];

    // Operation: Confirm Save Username and Password
    NSArray <__kindof NSOperation *> *operations = @[getUsername, promptCredntials,
                                                     getPassword, promptPassword,
                                                     promptSaveCredntials, promptSavePassword,
                                                     putUsername, putPassword];
    if (self = [super initWithOperations:operations]) {
        self.username = nil;
        self.password = nil;
    }
    return self;
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {

    // Operation 1 & 3: Credentials in keychain.
    //  If results are read from keychain, then MADOperationResultStringProtocol.
    //---
    if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
    
        if (((NSObject <MADOperationResultStringProtocol> *) operation).success) {

            switch (((NSObject <MADOperationResultStringProtocol> *) operation).readOperationType) {
                case username:
                    self.username = ((NSObject <MADOperationResultStringProtocol> *) operation).value;
                    self.usernameSet = true;
                    break;

                case password:
                    self.password = ((NSObject <MADOperationResultStringProtocol> *) operation).value;
                    self.passwordSet = true;
                    break;
                    
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
            self.username = ((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).credentials.username;
            self.usernameSet = true;
            self.password = ((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).credentials.password;
            self.passwordSet = true;
        }
    }
    
    //if (self.usernameSet && self.passwordSet) {
    //    [self finish];
    //}
    
//    if (operation conformsToProtocol:(Protocol *)) {
//        statements
//    }

}

@end
