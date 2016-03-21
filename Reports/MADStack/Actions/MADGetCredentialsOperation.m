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

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController {
    
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    
    // Operation: Read username.
    // -------------------------
    MADKeyChainOperationGet *getUsername = [[MADKeyChainOperationGet alloc] initWithKey:keyUsername];
    getUsername.readOperationType = username;
    
    
    // Operation: Prompt for username if condition is met.
    // ---------------------------------------------------
    MADPromptOperationCredentials *promptCredntials = [[MADPromptOperationCredentials alloc] initWithViewController:viewController];
    [promptCredntials addDependency:getUsername];
    
    // Condition: Username is missing.
    // ---------------------------------------------------
    MADOperationConditionMissingResultString *conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyUsername];
    [promptCredntials addCondition:conditionReadUsernameFailed];
    
    
    
    
    // Operation: Read password
    // ---------------------------------------------------
    MADKeyChainOperationGet *getPassword = [[MADKeyChainOperationGet alloc] initWithKey:keyPassword];
    getPassword.readOperationType = password;
    [getPassword addDependency:getUsername];
    
    // Condition: Username is found.
    // ---------------------------------------------------
    MADOperationConditionHasResultString *conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey:keyUsername];
    [getPassword addCondition:conditionReadUsername];
    
    // Condition: Password is missing.
    // ---------------------------------------------------
    MADOperationConditionMissingResultString *conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyPassword];
    
    // Operation: Prompt password
    // ---------------------------------------------------
    MADPromptOperationPassword *promptPassword = [[MADPromptOperationPassword alloc] initWithViewController:viewController];
    [promptPassword addDependency:getUsername];
    [promptPassword addDependency:getPassword];
    [promptPassword addDependency:promptCredntials];
    [promptPassword addCondition:conditionReadUsername];
    [promptPassword addCondition:conditionReadPasswordFailed];
    
    MADOperationConditionDisplayedAlert *displayedAlert = [[MADOperationConditionDisplayedAlert alloc] initWithTag:promptCredntials.hash];
    displayedAlert.reverseCondition = true;
    [promptPassword addCondition:displayedAlert];
    


    NSString *title = NSLocalizedString(TextSaveToKeyChain, TextSaveToKeyChain);
    NSString *message = NSLocalizedString(TextSaveToKeyChainMessagePassword, TextSaveToKeyChainMessagePassword);

    // Operation: Prompt save password
    // ---------------------------------------------------
    MADPromptOperationPolarQuestion *promptSavePassword = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title message:message viewController:viewController];
    [promptSavePassword addDependency:promptPassword];

    // Operation: Prompt save username and password
    // ---------------------------------------------------
    MADPromptOperationPolarQuestion *promptSaveCredntials = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title message:message viewController:viewController];
    [promptSaveCredntials addDependency:promptCredntials];
    


    // Condition: User entered a password.
    // ---------------------------------------------------

    MADOperationConditionPolarQuestionAffirmative *userEnteredPassword = [[MADOperationConditionPolarQuestionAffirmative alloc] init];
    [promptSavePassword addCondition:conditionReadPasswordFailed];
    [promptSavePassword addCondition:userEnteredPassword];
    [promptSavePassword addCompletionBlock:^{
        
    }];

    // Operation: Save password
    // ---------------------------------------------------

    //MADKeyChainOperationPut *putPassword = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword];
    //MADKeyChainOperationPut *putUsername = [[MADKeyChainOperationPut alloc] initWithKey:keyUsername];
    
    




    // Operation: Confirm Save Username and Password

    NSArray <__kindof NSOperation *> *operations = @[getUsername, promptCredntials,
                                                     getPassword, promptPassword];
    if (self = [super initWithOperations:operations]) {
        self.username = nil;
        self.password = nil;
    }
    return self;
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    //NSLog(@"%@", operation);
    if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
        if (((NSObject <MADOperationResultStringProtocol> *) operation).success) {
            //NSLog(@"Key: %@", ((NSObject <MADOperationResultStringProtocol> *) operation).key);
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
            //NSLog(@"Val: %@", ((NSObject <MADOperationResultStringProtocol> *) operation).value);
        }
    }
    
    if ([operation conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
        if (((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).gotCredentials) {
            self.username = ((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).credentials.username;
            self.usernameSet = true;
            self.password = ((NSObject <MADOperationHoldsCredentialsProtocol> *)operation).credentials.password;
            self.passwordSet = true;
        }
    }
    
    if (self.usernameSet && self.passwordSet) {
        [self finish];
    }
    
//    if (operation conformsToProtocol:(Protocol *)) {
//        statements
//    }

}

@end
