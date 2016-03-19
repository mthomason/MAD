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

static NSString * const TextSaveToKeyChain = @"Save to KeyChain";
static NSString * const TextSaveToKeyChainMessage = @"Would you like to save your username and password?";
static NSString * const TextSaveToKeyChainMessagePassword = @"Would you like to save your password?";

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
    [promptCredntials addCompletionBlock:^{
        NSString *title = NSLocalizedString(TextSaveToKeyChain, TextSaveToKeyChain);
        NSString *message = NSLocalizedString(TextSaveToKeyChainMessage, TextSaveToKeyChainMessage);
        
        MADOperationQueue *queue = [[MADOperationQueue alloc] init];
        MADPromptOperationPolarQuestion *savePassword = [[MADPromptOperationPolarQuestion alloc] initWithTitle:title
                                                                                                       message:message
                                                                                                viewController:viewController];
        
        [queue addOperation:savePassword];
    }];
    
    // Condition: Username is missing.
    // ---------------------------------------------------
    MADOperationConditionMissingResultString *conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyUsername];
    [promptCredntials addCondition:conditionReadUsernameFailed];
    
    // Operation: Read password
    // ---------------------------------------------------
    MADKeyChainOperationGet *getPassword = [[MADKeyChainOperationGet alloc] initWithKey:keyPassword];
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
    [promptPassword addCondition:conditionReadUsername];
    [promptPassword addCondition:conditionReadPasswordFailed];
    


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

    // Operation: Save password
    // ---------------------------------------------------

    MADKeyChainOperationPut *putPassword = [[MADKeyChainOperationPut alloc] initWithKey:keyPassword];
    MADKeyChainOperationPut *putUsername = [[MADKeyChainOperationPut alloc] initWithKey:keyUsername];
    
    




    // Operation: Confirm Save Username and Password

    NSArray <__kindof NSOperation *> *operations = @[getUsername, promptCredntials,
                                                     getPassword, promptPassword];
    self = [super initWithOperations:operations];
    return self;
}

@end
