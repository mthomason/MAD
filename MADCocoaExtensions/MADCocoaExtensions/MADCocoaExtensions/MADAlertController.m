//
//  MADAlertController.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAlertController.h"
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
													handler: ^(UIAlertAction *action) {
		UIAlertController *controller = alert;
		NSString *text = ((UITextField *)controller.textFields.firstObject).text.copy;
		handlerContinue(text);
	}];
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
													 style: UIAlertActionStyleCancel
												   handler: ^(UIAlertAction *action) {
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

+ (UIAlertController *)newAlertControllerEditLabel:(void (^)(UITextField *textField))textFieldConfig
										completion:(void (^)(UIAlertAction *action, NSString *text))completion {
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Edit Label", @"Edit Label")
																   message: NSLocalizedString(@"Please enter a new name for the document.", @"Please enter a new name for the document.")
															preferredStyle: UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:textFieldConfig];
	
	UITextField *textField = ((UIAlertController *)alert).textFields.firstObject;
	NSString *text = [textField.text copy];
	
	UIAlertAction *actionDefault = [UIAlertAction actionWithTitle: NSLocalizedString(@"Change", @"Change")
															style: UIAlertActionStyleDefault
														  handler: ^(UIAlertAction *action) {
		completion(action, text);
	}];
	[alert addAction:actionDefault];
	
	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
														   style: UIAlertActionStyleCancel
														 handler: nil];
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

	NSString *number = [NSNumberFormatter localizedStringFromNumber: [NSNumber numberWithUnsignedInteger: itemCount]
														numberStyle: NSNumberFormatterSpellOutStyle];

	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Confirm", @"Confirm")
																   message: [NSString stringWithFormat:messageTemplate, number]
															preferredStyle: UIAlertControllerStyleActionSheet];

	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
														   style: UIAlertActionStyleCancel
														 handler: handlerCancel];
	[alert addAction:actionCancel];

	NSString *titleDestructiveTemplate = itemCount > 1 ? NSLocalizedString(@"Remove %@ items", @"Remove %@ items (plural)") :
														 NSLocalizedString(@"Remove %@ item", @"Remove %@ item (singular)");

	UIAlertAction *actionDestructive = [UIAlertAction actionWithTitle: [NSString stringWithFormat:titleDestructiveTemplate, number]
																style: UIAlertActionStyleDestructive
															  handler: handlerConfirm];
	[alert addAction:actionDestructive];
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
	id alertController = [UIAlertController alertControllerWithTitle: title
															 message: message
													  preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
													   style: UIAlertActionStyleDefault
													 handler: nil];
	[alertController addAction:actionOK];
	return alertController;
}

+ (UIAlertController *)newAlertControllerErrorDisplayErrorWithTitle:(NSString *)title
															message:(NSString *)message
													  andCompletion:(void (^)(UIAlertAction *action))handlerContinue {
	id alertController = [UIAlertController alertControllerWithTitle: title
															 message: message
													  preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
													   style: UIAlertActionStyleDefault
													 handler: handlerContinue];
	[alertController addAction:actionOK];
	return alertController;
	
}

+ (UIAlertController *)newAlertControllerNofityTransactionComplete {
	id alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Transaction Complete", @"Transaction Complete")
												   message: NSLocalizedString(@"Software activated.", @"Software activated.")
											preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
													   style: UIAlertActionStyleDefault
													 handler: nil];
	[alert addAction:actionOK];
	return alert;
}

@end
