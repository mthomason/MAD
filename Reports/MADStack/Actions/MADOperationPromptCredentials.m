//
//  MADOperationPromptCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationPromptCredentials.h"
#import "MADMutualExclusive.h"
#import "madlog.h"

#import <MADCocoaExtensions/MADTextField.h>
#import <MADFoundation/MADKeyChain.h>
#import <MADFoundation/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>
#import <MAD/MADOperationKeyChainGet.h>

#import <UIKit/UIAlertController.h>
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>

@interface MADOperationPromptCredentials() <UITextFieldDelegate>

@property (nonatomic, weak) UIViewController *viewController;

@property (nonatomic, copy) NSString *usernameKey;
@property (nonatomic, copy) NSString *passwordKey;

@property (nonatomic, readwrite, assign) MADCredentialSource source;
@property (nonatomic, readwrite, copy) MADCredential *credentials;

@property (nonatomic, readwrite, assign) BOOL alertDisplayed;
@property (nonatomic, readwrite, assign) BOOL bypass;
@property (nonatomic, readwrite, assign) BOOL userContinue;
@property (nonatomic, readwrite, assign) BOOL displayingPrompt;

@property (nonatomic, readwrite, assign) BOOL gotCredentials;
@property (nonatomic, readwrite, assign) BOOL result;

@end

@implementation MADOperationPromptCredentials

- (void)dealloc { }

- (instancetype)initWithUsernameKey:(NSString *)usernameKey
						passwordKey:(NSString *)passwordKey
				  andViewController:(UIViewController *)viewController {

	if (self = [super init]) {

		_usernameKey = usernameKey.copy;
		_passwordKey = passwordKey.copy;
		_viewController = viewController;
		_source = MADCredentialSourceNone;
		_result = NO;
		_displayingPrompt = NO;
		_bypass = NO;
		_gotCredentials = NO;
		//MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
		//[self addCondition:condition];
		self.identifier = self.hash;
	}
	return self;
}

- (NSString *)valueForKey:(NSString *)key {
	if ([key isEqualToString:self.usernameKey]) {
		return self.credentials.username;
	} else if ([key isEqualToString:self.passwordKey]) {
		return self.credentials.password;
	} else {
		return nil;
	}
}

- (BOOL)manuallyInputtedCredentials {
	return self.alertDisplayed && self.result;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) {
		return [self finish];
	}

	self.displayingPrompt = YES;

	__block NSString *password;
	__block NSString *username;
	__block BOOL success = NO;
	
	MADOperationPromptCredentials * __weak weakself = self;
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Credentials", @"Credentials")
																				 message: NSLocalizedString(@"Please enter your credentials.", @"Please enter your credentials.")
																		  preferredStyle: UIAlertControllerStyleAlert];
		
		UIAlertController * __weak weakAlertController = alertController;
		
		UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
																style: UIAlertActionStyleDefault
															  handler: ^(UIAlertAction *action) {
			MADOperationPromptCredentials *strongself = weakself;
			UIAlertController *strongAlertController = weakAlertController;
			username = ((UITextField *)strongAlertController.textFields.firstObject).text.copy;
			password = ((UITextField *)(strongAlertController.textFields)[1]).text.copy;
			
			MADCredential *credentials = nil;
			if (username != nil && password != nil) {
				credentials = [[MADCredential alloc] initWithUsername:username andPassword:password];
				strongself.gotCredentials = YES;
				strongself.source = MADCredentialSourceCredentialPrompt;
			}
			strongself.alertDisplayed = YES;
			strongself.userContinue = YES;
			success = YES;
			[MADKeyChain saveToken: credentials.username forKey: strongself.usernameKey withDescription: MADKeyChainUsernameAccountDesc];
			[MADKeyChain saveToken: credentials.password forKey: strongself.passwordKey withDescription: MADKeyChainPasswordAccountDesc];
			strongself.credentials = [credentials copy];
			strongself.result = YES;
			for (UITextField *field in strongAlertController.textFields) {
				field.delegate = nil;
			}
			[strongself performSelector:@selector(finish)];
			strongAlertController = nil;
			
		}];
		[alertController addAction:actionAlertOK];

		UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
																	style: UIAlertActionStyleCancel
																  handler: ^(UIAlertAction *action) {
			MADOperationPromptCredentials *strongself = weakself;
			password = nil; username = nil;
			success = NO;
			strongself.alertDisplayed = YES;
			strongself.userContinue = NO;
			strongself.credentials = nil;
			strongself.result = NO;
			for (UITextField *field in weakAlertController.textFields) {
				field.delegate = nil;
			}
			NSError *error = [NSError errorWithDomain:NSStringFromClass([strongself class])
												 code:173 userInfo:nil];
			[strongself performSelector:@selector(finishWithError:) withObject:error];
		}];
		[alertController addAction:actionAlertCancel];
		
		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
			MADOperationPromptCredentials *strongself = weakself;
			UILabel *labelUsername = [[UILabel alloc] init];
			labelUsername.textColor = [UIColor lightGrayColor];
			labelUsername.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
			labelUsername.text = NSLocalizedString(@"Username: ", @"Username: ");
			[labelUsername sizeToFit];
			textField.leftView = labelUsername;
			textField.secureTextEntry = NO;
			textField.leftViewMode = UITextFieldViewModeAlways;
			textField.text = @"";
			textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			textField.clearButtonMode = UITextFieldViewModeAlways;
			textField.delegate = strongself;
		}];
		[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
			MADOperationPromptCredentials *strongself = weakself;
			UILabel *passwordLabel = [[UILabel alloc] init];
			passwordLabel.textColor = [UIColor lightGrayColor];
			passwordLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
			passwordLabel.text = NSLocalizedString(@"Password: ", @"Password: ");
			[passwordLabel sizeToFit];
			textField.leftView = passwordLabel;
			textField.secureTextEntry = YES;
			textField.leftViewMode = UITextFieldViewModeAlways;
			textField.text = @"";
			textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			textField.clearButtonMode = UITextFieldViewModeAlways;
			textField.delegate = strongself;
		}];

		
		UIViewController *viewController = self.viewController;
		viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		[viewController  presentViewController: alertController animated: YES completion:^{
			[weakAlertController.textFields enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
				((UILabel *)textField.leftView).textColor = textField.isFirstResponder ? [UIColor darkGrayColor] : [UIColor lightGrayColor];
				[textField.leftView setNeedsDisplay];
			}];
		}];
	}];

}

- (BOOL)alertDisplayedAffirmed {
	return self.alertDisplayed && self.userContinue;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
