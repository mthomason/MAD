//
//  MADOperationGetCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationGetCredentials.h"

#import <MADAPI/MADDatabaseConnection.h>

#import <MADFoundation/NSOperation+Advanced.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperationBooleanAnd.h>
#import <MADFoundation/MADKeyChain.h>
#import <MADFoundation/MADOperationConditionMissingResultString.h>
#import <MADFoundation/MADOperationConditionHasResultString.h>

#import <MAD/MADOperationKeyChainGet.h>
#import <MAD/MADOperationKeyChainPut.h>

#import "MADOperationPromptCredentials.h"
#import "MADOperationPromptPassword.h"
#import "MADOperationConditionDisplayedAlert.h"
#import "madlog.h"

static NSString * const TextSaveToKeyChain = @"Save to KeyChain";
static NSString * const TextSaveToKeyChainMessage = @"Would you like to save your username and password?";
static NSString * const TextSaveToKeyChainMessagePassword = @"Would you like to save your password?";

@interface MADOperationGetCredentials ()

	@property (nonatomic, copy) NSString *username;
	@property (nonatomic, copy) NSString *password;

	@property (nonatomic, assign) BOOL passwordSet;
	@property (nonatomic, assign) BOOL usernameSet;
	@property (nonatomic, assign) BOOL shortCircut;

	@property (nonatomic, strong) MADDatabaseConnection *databaseConnection;
	@property (nonatomic, weak) UIViewController *viewController;

@end

@implementation MADOperationGetCredentials {
	NSString *_keyUsername, *_keyPassword;
	BOOL _finishedPromptPassword;
	BOOL _finishedPromptCredentals;
}

- (void)dealloc {
	_databaseConnection = nil;
	_viewController = nil;
}

- (instancetype)initWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
							viewController: (UIViewController *)viewController {
	if (self = [super init]) {

		_finishedPromptPassword = NO;
		_finishedPromptCredentals = NO;
		_databaseConnection = databaseConnection;
		_viewController = viewController;
	}
	return self;
}

- (BOOL)isAsynchronous {
	return YES;
}

- (BOOL)gotCredentials { return self.usernameSet && self.passwordSet; }

- (BOOL)completedPrompt { return _finishedPromptPassword || _finishedPromptCredentals; }

- (BOOL)manuallyInputtedCredentials { return [self gotCredentials] && [self completedPrompt]; }

- (void)execute {
	MADDatabaseConnection *databaseConnection = _databaseConnection;
	UIViewController *viewController = _viewController;
	
	if ((_shortCircut || self.cancelled || ![databaseConnection requiresCredentials]))
		return [self finish];

	NSString *key = databaseConnection.connectionString;
	_keyUsername = [MADKeyChain newKeyForUsernameWithMainKey: key];
	_keyPassword = [MADKeyChain newKeyForPasswordWithMainKey: key];
	
	// Condition: Username is missing.
	MADOperationConditionMissingResultString *conditionReadUsernameFailed;
	conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey: _keyUsername];

	// Condition: Username is found.
	MADOperationConditionHasResultString *conditionReadUsername;
	conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey: _keyUsername];

	// ---------------------------------------------------
	// Operation 1: Read username.
	// -------------------------
	MADOperationKeyChainGet *getUsername = [[MADOperationKeyChainGet alloc] initWithKey: _keyUsername
																		withDescription: MADKeyChainUsernameAccountDesc];
	getUsername.readOperationType = MADKeyChainReadOperationTypeUsername;
	
	// ---------------------------------------------------
	// Operation 2: Prompt for credentials if condition is met.
	// Conditions:  Username is missing.
	// ---------------------------------------------------
	MADOperationPromptCredentials *promptCredntials = [[MADOperationPromptCredentials alloc] initWithUsernameKey: _keyUsername
																									 passwordKey: _keyPassword
																							   andViewController: viewController];
	[promptCredntials addDependency:getUsername];
	[promptCredntials addCondition:conditionReadUsernameFailed];

	// Condition: Suppressed prompt credentials
	MADOperationConditionDisplayedAlert *suppressedAlertCredntials = [[MADOperationConditionDisplayedAlert alloc] initWithOperationIdentifier:promptCredntials.identifier];
	suppressedAlertCredntials.reverseCondition = YES;

	// ---------------------------------------------------
	// Operation 3: Read password
	// Conditions:  Username is found.
	// ---------------------------------------------------
	MADOperationKeyChainGet *getPassword = [[MADOperationKeyChainGet alloc] initWithKey: _keyPassword
																		withDescription: MADKeyChainPasswordAccountDesc];
	getPassword.readOperationType = MADKeyChainReadOperationTypePassword;
	[getPassword addDependency:getUsername];
	[getPassword addCondition:conditionReadUsername];

	// Condition: Get password failed
	MADOperationConditionMissingResultString *conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:_keyPassword];

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
	MADOperationPromptPassword *promptPassword = [[MADOperationPromptPassword alloc] initWithPasswordKey: _keyPassword
																					   andViewController: viewController];
	[promptPassword addDependency:getUsername];
	[promptPassword addDependency:getPassword];
	[promptPassword addDependency:promptCredntials];
	[promptPassword addCondition:conditionPromptPasswordBoolAnd];
	

	NSArray <__kindof NSOperation *> *operations = @[getUsername, promptCredntials, getPassword, promptPassword];
	
	__weak MADOperationGetCredentials *wself = self;
	NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
		__strong MADOperationGetCredentials *sself = wself;
		os_log_info(OS_LOG_DEFAULT, "%s - block", __PRETTY_FUNCTION__);
		sself.databaseConnection = nil;
		sself.viewController = nil;
		[sself finish];
	}];

	[self addOperations:operations finishingOperation:finishingOperation];
	[super execute];
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray<NSError *> *)errors {
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
	//[((MADOperation *)operation) cleanup];
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
