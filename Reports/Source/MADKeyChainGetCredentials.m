//
//  MADKeyChainGetCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADKeyChainGetCredentials.h"
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADKeyChain.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UILabel.h>

@interface MADKeyChainGetCredentials() <UITextFieldDelegate>

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) UIAlertController *alertController;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy, readwrite) MADCredential *credential;

@end

@implementation MADKeyChainGetCredentials

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

#pragma mark - Operation

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController {

	if (self = [super init]) {
		self.viewController = viewController;
		self.key = [key copy];
		self.source = MADCredentialSourceNone;
		self.alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Credentials", @"Credentials")
																   message: NSLocalizedString(@"Please enter your credentials.", @"Please enter your credentials.")
															preferredStyle: UIAlertControllerStyleAlert];
	}
	return self;

}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) return [self finish];

	const char PromptForUsernameAndPassword = 1;
	const char PromptForPassword = 2;
	const char PromptForNothing = 3;
	
	CFDataRef queryUsernameData = NULL, queryPasswordData = NULL;

	//Read username and password.
	NSDictionary *queryUsername = [MADKeyChain queryUsernameDefination:self.key];
	OSStatus queryStatusUsername = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
	
	NSDictionary *queryPassword = [MADKeyChain queryPasswordDefination:self.key];
	OSStatus queryStatusPassword = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
	
	char status = PromptForUsernameAndPassword;
	if (queryStatusUsername == errSecSuccess) {
		status = queryStatusPassword == errSecSuccess ? PromptForNothing : PromptForPassword;
	}
	
	//Sanity check the data
	if (status == PromptForNothing) {
		if (queryUsernameData == NULL || queryPasswordData == NULL)  status = PromptForUsernameAndPassword;
	} else if (status == PromptForPassword && queryPasswordData == NULL) {
		status = PromptForUsernameAndPassword;
	}
	
	if (self.cancelled) return [self finish];
	
	switch (status) {
			
		case PromptForNothing: {
			NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData encoding: NSUTF8StringEncoding];
			NSString *password = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryPasswordData encoding: NSUTF8StringEncoding];
			MADCredential *c = [[MADCredential alloc] initWithUsername:username andPassword:password];
			self.credential = c;
			self.source = MADCredentialSourceKeychain;
			[self finish];
			break;
		}
			
		case PromptForPassword: {
			NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData encoding:NSUTF8StringEncoding];
			[self promptForPasswordGivenUsername: username];
			break;
		}

		case PromptForUsernameAndPassword: {
			[self promptForUsernameAndPassword];
			break;
		}

		default: {
			[self finishWithError:[NSError errorWithDomain:@"MADKCGC" code:status userInfo:nil]];
			break;
		}
	}
}

- (void)promptForUsernameAndPassword {

	NSString *ok = NSLocalizedString(@"Continue", @"Continue");
	NSString *cancel = NSLocalizedString(@"Cancel", @"Cancel");
	
	UIAlertController *alertController = self.alertController;

	void (^ __nullable actionContinue)(UIAlertAction *action) = ^(UIAlertAction *action) {
		MADCredential *c = [[MADCredential alloc] initWithUsername: ((UITextField *)alertController.textFields.firstObject).text
													   andPassword: ((UITextField *)[alertController.textFields objectAtIndex:1]).text];
		self.credential = c;
		self.source = MADCredentialSourceCredentialPrompt;
		[self finish];
	};
	
	void (^ __nullable actionCancel)(UIAlertAction *action) = ^(UIAlertAction *action) {
		self.source = MADCredentialSourceNone;
		[self finish];
	};
	
	void (^ __nullable actionTextFieldWithConfigurationUsername)(UITextField *textField) = ^(UITextField *textField) {
		[MADKeyChainGetCredentials configureTextFieldForUsername:&textField];
		textField.delegate = self;
	};
	
	void (^ __nullable actionTextFieldWithConfigurationPassword)(UITextField *textField) = ^(UITextField *textField) {
		[MADKeyChainGetCredentials configureTextFieldForPassword:&textField];
		textField.delegate = self;
	};
	
	UIAlertAction *actionAlertKk = [UIAlertAction actionWithTitle: ok
															style: UIAlertActionStyleDefault
														  handler: actionContinue];
	
	UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
																style: UIAlertActionStyleCancel
															  handler: actionCancel];
	
	[alertController addAction:actionAlertKk];
	[alertController addAction:actionAlertCancel];
	
	[alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationUsername];
	[alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationPassword];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		UIViewController *topViewController = self.viewController;
		topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		[topViewController  presentViewController: alertController animated: YES completion: nil];
	}];
	
}

- (void)promptForPasswordGivenUsername:(NSString *)username {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Password", @"Password")
																			 message: NSLocalizedString(@"Please enter your password.", @"Please enter your password.")
																	  preferredStyle: UIAlertControllerStyleAlert];

	UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
															style: UIAlertActionStyleDefault
														  handler: ^(UIAlertAction *action) {
		MADCredential *c = [[MADCredential alloc] initWithUsername: username
													   andPassword: ((UITextField *)alertController.textFields.firstObject).text];
		self.credential = c;
		self.source = MADCredentialSourcePasswordPrompt;
		[self finish];
	}];
	
	UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
																style: UIAlertActionStyleCancel
															  handler: ^(UIAlertAction *action) {
		self.credential = nil;
		self.source = MADCredentialSourceNone;
		[self finish];
	}];
	[alertController addAction:actionAlertOK];
	[alertController addAction:actionAlertCancel];
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.delegate = self;
	}];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		UIViewController *topViewController = self.viewController;
		topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		[topViewController  presentViewController: alertController animated: YES completion: nil];
	}];
	
}

+ (void)configureTextFieldForPassword:(UITextField * __autoreleasing *)textField {
	UILabel *labelPassword = [[UILabel alloc] init];
	labelPassword.textColor = [UIColor lightGrayColor];
	labelPassword.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	labelPassword.text = NSLocalizedString(@"Password: ", @"Password: ");
	[labelPassword sizeToFit];
	(*textField).leftView = labelPassword;
	(*textField).secureTextEntry = YES;
	(*textField).leftViewMode = UITextFieldViewModeAlways;
	(*textField).text = @"";
	(*textField).autocapitalizationType = UITextAutocapitalizationTypeNone;
	(*textField).clearButtonMode = UITextFieldViewModeAlways;
}

+ (void)configureTextFieldForUsername:(UITextField * __autoreleasing *)textField {
	UILabel *labelUsername = [[UILabel alloc] init];
	labelUsername.textColor = [UIColor lightGrayColor];
	labelUsername.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	labelUsername.text = NSLocalizedString(@"Username: ", @"Username: ");
	[labelUsername sizeToFit];
	(*textField).leftView = labelUsername;
	(*textField).secureTextEntry = NO;
	(*textField).leftViewMode = UITextFieldViewModeAlways;
	(*textField).text = @"";
	(*textField).autocapitalizationType = UITextAutocapitalizationTypeNone;
	(*textField).clearButtonMode = UITextFieldViewModeAlways;
}

@end
