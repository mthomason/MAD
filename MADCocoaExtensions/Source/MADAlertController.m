//
//  MADAlertController.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADAlertController.h"
#if TARGET_OS_IPHONE
#import "MADAlertControllerAlertRemovedProtocol.h"
#import "MADTextField.h"

@implementation MADAlertController

+ (UIAlertController *)newAlertControllerPromptForPasswordGivenUsername:(NSString *)username
															   password:(void (^)(UITextField *textField))passwordSetup
																 submit:(void (^)(NSString *password))handlerContinue
																 cancel:(void (^)(void))handlerCancel {
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Password", @"Password")
																   message: NSLocalizedString(@"Please enter your password.", @"Please enter your password.")
															preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *confirm = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
													  style: UIAlertActionStyleDefault
													handler: ^(UIAlertAction *__unused action) {
		UIAlertController *controller = alert;
		NSString *text = [((UITextField *)controller.textFields.firstObject).text copy];
		handlerContinue(text);
	}];
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
													 style: UIAlertActionStyleCancel
												   handler: ^(UIAlertAction *__unused action) {
		handlerCancel();
	}];
	[alert addAction:confirm];
	[alert addAction:cancel];
	[alert addTextFieldWithConfigurationHandler:passwordSetup];
	
	return alert;
	
}

+ (UIAlertController *)removeCredentials:(void (^)(UIAlertAction *action))handlerDestructive
								  cancel:(void (^)(UIAlertAction *action))handlerCancel {
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Remove Saved Password", @"Remove Saved Password")
																   message: NSLocalizedString(@"Should we remove the password saved in your keychain?", @"Should we remove the password saved in your keychain?")
															preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Keep", @"Keep")
												 style: UIAlertActionStyleDefault
											   handler: handlerCancel];
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Remove", @"Remove")
													 style: UIAlertActionStyleDestructive
												   handler: handlerDestructive];
	[alert addAction:ok];
	[alert addAction:cancel];
	return alert;
}

+ (UIAlertController *)newAlertControllerSaveCredentials:(void (^)(UIAlertAction *action))handlerContinue
												  cancel:(void (^)(UIAlertAction *action))handlerCancel {
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Save Credentials", @"Save Credentials")
																   message: NSLocalizedString(@"Would you like to save the credentials to your key chain?", @"Would you like to save the credentials to your key chain?")
															preferredStyle: UIAlertControllerStyleAlert];

	UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
															style: UIAlertActionStyleDefault
														  handler: handlerContinue];
	[alert addAction:actionConfirm];
	
	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
														   style: UIAlertActionStyleCancel
														 handler: handlerCancel];
	[alert addAction:actionCancel];
	return alert;
}

+ (UIAlertController *)newAlertControllerDeleteItems:(NSUInteger)itemCount
											 confirm:(void (^)(UIAlertAction *action))handlerConfirm
											  cancel:(void (^)(UIAlertAction *action))handlerCancel {

	NSString *messageTemplate = itemCount > 1 ? NSLocalizedString(@"Are you sure you would like to delete %@ items?  This action is final.",
																  @"Delete message template (plural)") :
												NSLocalizedString(@"Are you sure you would like to delete %@ item?  This action is final.",
																  @"Delete message template (singular)");

	NSString *numberStr = [NSNumberFormatter localizedStringFromNumber: [NSNumber numberWithUnsignedInteger: itemCount]
														   numberStyle: NSNumberFormatterSpellOutStyle];

	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Confirm", @"Confirm")
																   message: [NSString stringWithFormat:messageTemplate, numberStr]
															preferredStyle: UIAlertControllerStyleActionSheet];

	[alert addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
											  style: UIAlertActionStyleCancel
											handler: handlerCancel]];

	NSString *titleDestructiveTemplate = itemCount > 1 ? NSLocalizedString(@"Remove %@ items", @"Remove %@ items (plural)") :
														 NSLocalizedString(@"Remove %@ item", @"Remove %@ item (singular)");

	[alert addAction:[UIAlertAction actionWithTitle: [NSString stringWithFormat:titleDestructiveTemplate, numberStr]
											  style: UIAlertActionStyleDestructive
											handler: handlerConfirm]];
	return alert;
}

+ (UIAlertController *)newAlertControllerError:(NSError *)error {
	NSString *title = [error.localizedDescription copy] ?: @"";
	NSString *messageStart = [error.localizedFailureReason copy] ?: @"";
	NSString *localizedRecoverySuggestion = [error.localizedRecoverySuggestion copy] ?: @"";
	NSString *message = [messageStart stringByAppendingString:localizedRecoverySuggestion];
	if (message.length <= 0) {
		message = NSLocalizedString(@"Unknown error.", @"Unknown error.");
	}
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
																			 message: message
																	  preferredStyle: UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
														style: UIAlertActionStyleDefault
													  handler: nil]];
	return alertController;
}

+ (UIAlertController *)newAlertControllerErrorDisplayErrorWithTitle:(NSString *)title
															message:(NSString *)message
													  andCompletion:(void (^)(UIAlertAction *action))handlerContinue {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
																			 message: message
																	  preferredStyle: UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
														style: UIAlertActionStyleDefault
													  handler: handlerContinue]];
	return alertController;
	
}

+ (UIAlertController *)newAlertControllerNofityTransactionComplete {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Transaction Complete", @"Transaction Complete")
																   message: NSLocalizedString(@"Software activated.", @"Software activated.")
															preferredStyle: UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
											  style: UIAlertActionStyleDefault
											handler: nil]];
	return alert;
}

@end
#endif
