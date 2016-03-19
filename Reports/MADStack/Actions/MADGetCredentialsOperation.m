//
//  MADGetCredentialsOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADGetCredentialsOperation.h"
#import <MAD/MTKeyChain.h>
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultString.h"
#import "MADPromptOperationPassword.h"

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


    NSArray <__kindof NSOperation *> *operations = @[getUsername, promptCredntials,
                                                     getPassword, promptPassword];
    self = [super initWithOperations:operations];
    return self;
}

@end
