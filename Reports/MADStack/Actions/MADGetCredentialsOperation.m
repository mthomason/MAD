//
//  MADGetCredentialsOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADGetCredentialsOperation.h"
#import <MAD/MTKeyChain.h>
#import <MAD/MTDatabaseConnection.h>
#import "NSOperation+Advanced.h"
#import "MADOperationQueue.h"
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultString.h"
#import "MADPromptOperationPassword.h"
#import "MADPromptOperationPolarQuestion.h"
#import "MADPromptOperationDisplayError.h"
#import "MADDatabaseOperationTestConnection.h"
#import "MADKeyChainOperationPut.h"
#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationConditionDisplayedAlert.h"
#import "MADOperationBooleanAnd.h"
#import "MADDefer.h"

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

- (void)dealloc {
    NSLog(@"Operation deallocated.");
}

- (MADCredential *)credentials {
    if (self.passwordSet && self.usernameSet) {
        MADCredential * __autoreleasing credentials = [[MADCredential alloc] initWithUsername:self.username andPassword:self.password];
        return credentials;
    } else {
        return nil;
    }
}

- (bool)gotCredentials { return self.usernameSet && self.passwordSet; }

- (instancetype)initWithDatabaseConnection: (MTDatabaseConnection *)databaseConnection
                            viewController: (UIViewController *)viewController {
    
    if (self = [super init]) {
    
        NSString *key = databaseConnection.connectionString;
        NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
        NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
        
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
        suppressedAlertCredntials.reverseCondition = true;
        
        MADOperationConditionMissingResultString *conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyPassword];
        
        NSArray <NSObject <MADOperationCondition> *> *conditionsForPromptPassword = @[conditionReadUsername, conditionReadPasswordFailed, suppressedAlertCredntials];
        
        MADOperationBooleanAnd *conditionPromptPasswordBoolAnd = [[MADOperationBooleanAnd alloc] initWithConditions:conditionsForPromptPassword];
        [promptPassword addCondition:conditionPromptPasswordBoolAnd];
        
        NSString *title = NSLocalizedString(TextSaveToKeyChain, TextSaveToKeyChain);
        NSString *messageCredntialsPrompt = NSLocalizedString(TextSaveToKeyChainMessage, TextSaveToKeyChainMessage);
        
        
        // ---------------------------------------------------
        // Operation 5a: Test the connection (credentials prompt)
        // ---------------------------------------------------
        MADDatabaseOperationTestConnection *testConnectionOperationCredentials = [[MADDatabaseOperationTestConnection alloc] initWithDatabaseConnection: databaseConnection];
        [testConnectionOperationCredentials addDependency:getUsername];
        [testConnectionOperationCredentials addDependency:getPassword];
        [testConnectionOperationCredentials addDependency:promptCredntials];
        
        MADOperationConditionPolarQuestionAffirmative *promptForCredentialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptCredntials.hash];
        [testConnectionOperationCredentials addCondition: promptForCredentialsAffirmative];
        
        // ---------------------------------------------------
        // Operation 5b: Test the connection (password prompt)
        // ---------------------------------------------------
        MADDatabaseOperationTestConnection *testConnectionOperationPassword = [[MADDatabaseOperationTestConnection alloc] initWithDatabaseConnection: databaseConnection];
        [testConnectionOperationPassword addDependency:getUsername];
        [testConnectionOperationPassword addDependency:getPassword];
        [testConnectionOperationPassword addDependency:promptPassword];
        
        MADOperationConditionPolarQuestionAffirmative *promptForPasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptPassword.hash];
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
        MADPromptOperationPolarQuestion *promptSavePassword = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title message:messagePasswordPrompt viewController:viewController];
        [promptSavePassword addDependency:testConnectionOperationPassword];
        [promptSavePassword addDependency:promptPassword];
        
        [promptSavePassword addCondition:promptForPasswordAffirmative];
        
        // ---------------------------------------------------
        // Operation 7: Save username
        // Dependency:  Prompt save credentials.
        // Conditions:  User said yes to save credentials.
        // ---------------------------------------------------
        MADKeyChainOperationPut *putUsername = [[MADKeyChainOperationPut alloc] initWithKey:keyUsername description:MTKeyChainUsernameAccountDesc];
        MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSaveCredntials.hash];
        [putUsername addDependency:promptCredntials];
        [putUsername addDependency:promptSaveCredntials];
        [putUsername addCondition:promptToSaveCredntialsAffirmative];
        
        // ---------------------------------------------------
        // Operation 8: Save password
        // Conditions:  User said yes to save credentials OR
        //              User said yes to save password.
        // ---------------------------------------------------
        MADKeyChainOperationPut *putPasswordCredentials = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
        MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmativePassword = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSaveCredntials.hash];
        [putPasswordCredentials addDependency:promptCredntials];
        [putPasswordCredentials addDependency:promptSaveCredntials];
        [putPasswordCredentials addCondition:promptToSaveCredntialsAffirmativePassword];
        
        MADKeyChainOperationPut *putPassword = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
        MADOperationConditionPolarQuestionAffirmative *promptToSavePasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithTag:promptSavePassword.hash];
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
        self.username = nil;
        self.password = nil;
        
        NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self finish];
        }];
        
        [self addOperations:operations finishingOperation:finishingOperation];
    }
    
    return self;
}
/*
- (void)execute {
    
    MADGroupOperation * __weak wself = self;
    self.finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
        MADGroupOperation *sself = wself;
        defer(^{
            [sself finish];
        });
    }];
    
    self.internalQueue.suspended = NO;
    [self.internalQueue addOperation:self.finishingOperation];
}
*/
- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {

    // Operation 1 & 3: Credentials in keychain.
    //  If results are read from keychain, then MADOperationResultStringProtocol.
    //---
    if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
    
        if (((NSObject <MADOperationResultStringProtocol> *) operation).success) {

            switch (((NSObject <MADOperationResultStringProtocol> *) operation).readOperationType) {
                case MADKeyChainReadOperationTypeUsername:
                    self.username = ((NSObject <MADOperationResultStringProtocol> *) operation).value;
                    self.usernameSet = true;
                    break;

                case MADKeyChainReadOperationTypePassword:
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
}

@end
