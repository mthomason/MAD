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

static NSString * const MADTitleButtonDismiss          = @"Dismiss";
static NSString * const MADTitleButtonLocalOnly        = @"Local Only";
static NSString * const MADTitleButtonCloud            = @"iCloud";
static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";
static NSString * const MADButtonChange                = @"Change";
static NSString * const MADButtonConfirm               = @"Confirm";
static NSString * const MADButtonKeep                  = @"Keep";
static NSString * const MADButtonRemove                = @"Remove";

@interface MADAlertController ()

@end

@implementation MADAlertController

+ (instancetype)newAlertControllerAddedDocument {
	NSString *MADTitleNewDocument = @"New Document";
	NSString *MADMessageNewDocument = @"Added document.";
	NSString *newdoc = NSLocalizedString(MADTitleNewDocument, MADTitleNewDocument);
	NSString *addeddoc = NSLocalizedString(MADMessageNewDocument, MADMessageNewDocument);
	NSString *continueb = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	id alert = [UIAlertController alertControllerWithTitle: newdoc
												   message: addeddoc
											preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle: continueb
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction:ok];
	return alert;
}

+ (instancetype)newAlertControllerPromptForPasswordGivenUsername:(NSString *)username
														password:(void (^)(UITextField *textField))passwordSetup
														  submit:(void (^)(NSString *password))handlerContinue
														  cancel:(void (^)(void))handlerCancel {
	NSString *MADTitlePassword = @"Password";
	NSString *MADMessagePassword = @"Please enter your password.";
	NSString *title = NSLocalizedString(MADTitlePassword, MADTitlePassword);
	NSString *message = NSLocalizedString(MADMessagePassword, MADMessagePassword);
	NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);

	id alertController;
	alertController = [UIAlertController alertControllerWithTitle: title
														  message: message
												   preferredStyle: UIAlertControllerStyleAlert];
	
	void (^actionConfirmHander)(UIAlertAction *);
	actionConfirmHander = ^(UIAlertAction *action) {
		UIAlertController *controller = alertController;
		NSString *text = ((UITextField *)controller.textFields.firstObject).text.copy;
		handlerContinue(text);
	};
	
	UIAlertAction *actionConfirm;
	actionConfirm = [UIAlertAction actionWithTitle: ok
											 style: UIAlertActionStyleDefault
										   handler: actionConfirmHander];
	
	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
														   style: UIAlertActionStyleCancel
														 handler:^(UIAlertAction *action) {
															 handlerCancel();
														 }];
	[alertController addAction:actionConfirm];
	[alertController addAction:actionCancel];
	[alertController addTextFieldWithConfigurationHandler:passwordSetup];

	return alertController;
	
}
+ (instancetype)newAlertControllerPromptForUsername:(void (^)(UITextField *textField))usernameSetup
										   password:(void (^)(UITextField *textField))passwordSetup
											 submit:(void (^)(NSString *username, NSString *password))handlerContinue
											 cancel:(void (^)(void))handlerCancel {
	
	NSString *MADTitleCredentials = @"Credentials";
	NSString *MADMessageCredentials = @"Please enter your credentials.";
	NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
	NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
	NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);

	id alertController;
	UIAlertAction *actionConfirm, *actionCancel;

	alertController = [UIAlertController alertControllerWithTitle: title
														  message: message
												   preferredStyle: UIAlertControllerStyleAlert];
	
	NSString *t1 = ((MADAlertController *)alertController).textFields.firstObject.text.copy,
			 *t2 = ((MADAlertController *)alertController).textFields[1].text.copy;
	
	actionConfirm = [UIAlertAction actionWithTitle: ok
											 style: UIAlertActionStyleDefault
										   handler:^(UIAlertAction *action) {
											   
											   handlerContinue(t1, t2);
											   
										   }];
	
	actionCancel = [UIAlertAction actionWithTitle: cancel
											style: UIAlertActionStyleCancel
										  handler:^(UIAlertAction *action) {
											  handlerCancel();
										  }];
	
	[alertController addAction:actionConfirm];
	[alertController addAction:actionCancel];
	
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		MADTextField *textFieldFormatter = [[MADTextField alloc] init];
		textFieldFormatter.handleConfigureUsername(textField);
		usernameSetup(textField);
	}];
	
	[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		MADTextField *textFieldFormatter = [[MADTextField alloc] init];
		textFieldFormatter.handleConfigurePassword(textField);
		passwordSetup(textField);
	}];
	
	return alertController;
}

+ (instancetype)removeCredentials:(void (^)(UIAlertAction *action))handlerDestructive
						   cancel:(void (^)(UIAlertAction *action))handlerCancel {

	NSString *MADTitleRemoveCredentials = @"Remove Saved Password";
	NSString *MADMessageRemoveCredentials = @"Should we remove the password saved in your "
											@"keychain?";
	NSString *title = NSLocalizedString(MADTitleRemoveCredentials, MADTitleRemoveCredentials);
	NSString *message = NSLocalizedString(MADMessageRemoveCredentials, MADMessageRemoveCredentials);
	NSString *keep = NSLocalizedString(MADButtonKeep, MADButtonKeep);
	NSString *remove = NSLocalizedString(MADButtonRemove, MADButtonRemove);
	
	id alert = [UIAlertController alertControllerWithTitle: title
																   message: message
															preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle: keep
												 style: UIAlertActionStyleDefault
											   handler: handlerCancel];
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle: remove
													 style: UIAlertActionStyleDestructive
												   handler: handlerDestructive];
	[alert addAction:ok];
	[alert addAction:cancel];
	return alert;
}

+ (instancetype)newAlertControllerSaveCredentials:(void (^)(UIAlertAction *action))handlerContinue
										   cancel:(void (^)(UIAlertAction *action))handlerCancel {

	NSString *MADTitleSaveCredentials = @"Save Credentials";
	NSString *MADMessageSaveCredentials = @"Would you like to save the credentials to your "
										  @"key chain?";

	NSString *title = NSLocalizedString(MADTitleSaveCredentials, MADTitleSaveCredentials);
	NSString *message = NSLocalizedString(MADMessageSaveCredentials, MADMessageSaveCredentials);
	NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
	
	id alertController = [UIAlertController alertControllerWithTitle: title
																			 message: message
																	  preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle: ok
													   style: UIAlertActionStyleDefault
													 handler: handlerContinue];
	
	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
														   style: UIAlertActionStyleCancel
														 handler: handlerCancel];
	
	[alertController addAction:actionConfirm];
	[alertController addAction:actionCancel];
	return alertController;
}

+ (instancetype)newAlertControllerNotifyCloudSignOut:(void (^)(UIAlertAction *action))handler {
	NSString *MADTitleCloudSignout = @"iCloud Sign Out";
	NSString *MADMessageCloudSignout = @"You have signed out of the iCloud account "
									   @"previously used to store documents. Sign "
									   @"back in to access those documents.";
	NSString *title = NSLocalizedString(MADTitleCloudSignout, MADTitleCloudSignout);
	NSString *message = NSLocalizedString(MADMessageCloudSignout, MADMessageCloudSignout);
	NSString *ok = NSLocalizedString(MADTitleButtonDismiss, MADTitleButtonDismiss);
	id alertController = [UIAlertController alertControllerWithTitle: title
																			 message: message
																	  preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle: ok
													   style: UIAlertActionStyleDefault
													 handler: handler];
	[alertController addAction:actionConfirm];
	return alertController;
}

+ (instancetype)newAlertControllerEditLabel:(void (^)(UITextField *textField))textFieldConfig
								 completion:(void (^)(UIAlertAction *action, NSString *text))completion {
	
	id alert;
	void (^handleActionChange)(UIAlertAction *);

	NSString *MADTitleEditLabel = @"Edit Label";
	NSString *MADMessageEditLabel = @"Please enter a new name for the document.";
	NSString *title = NSLocalizedString(MADTitleEditLabel, MADTitleEditLabel);
	NSString *message = NSLocalizedString(MADMessageEditLabel, MADMessageEditLabel);
	NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
	NSString *change = NSLocalizedString(MADButtonChange, MADButtonChange);
	
	alert = [UIAlertController alertControllerWithTitle: title
												message: message
										 preferredStyle: UIAlertControllerStyleAlert];

	UITextField *textField = ((MADAlertController *)alert).textFields.firstObject;
	NSString *text = textField.text.copy;

	handleActionChange = ^(UIAlertAction *action) {
		completion(action, text);
	};
	
	UIAlertAction *actionDefault, *actionCancel;
	actionDefault = [UIAlertAction actionWithTitle: change
											 style: UIAlertActionStyleDefault
										   handler: handleActionChange];
	
	actionCancel = [UIAlertAction actionWithTitle: cancel
											style: UIAlertActionStyleCancel
										  handler: nil];
	
	[alert addTextFieldWithConfigurationHandler:textFieldConfig];
	
	[alert addAction:actionDefault];
	[alert addAction:actionCancel];
	return alert;
}

+ (instancetype)newAlertControllerNotConfiguredForEmail {
	NSString *MADTitleEmailConfigNot = @"Alert";
	NSString *MADMessageEmailConfigNot = @"Device is not configured for email.";
	NSString *title = NSLocalizedString(MADTitleEmailConfigNot, MADTitleEmailConfigNot);
	NSString *message = NSLocalizedString(MADMessageEmailConfigNot, MADMessageEmailConfigNot);
	NSString *titleButton = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	id alert = [UIAlertController alertControllerWithTitle: title
												   message: message
											preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle: titleButton
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction:ok];
	return alert;
}

+ (instancetype)newAlertControllerDeleteItems:(NSUInteger)itemCount
									  confirm:(void (^)(UIAlertAction *action))handlerConfirm
									   cancel:(void (^)(UIAlertAction *action))handlerCancel {
	
	NSNumber *selectedItemsCount = [[NSNumber alloc] initWithUnsignedInteger:itemCount];
	NSString *number = [NSNumberFormatter localizedStringFromNumber: selectedItemsCount
														numberStyle: NSNumberFormatterSpellOutStyle];
	NSString *MADMessageDeleteItemsPlural = @"Are you sure you would like to delete %@ "
											@"items?  This action is final.";
	NSString *title = NSLocalizedString(MADButtonConfirm, MADButtonConfirm);
	NSString *messageTemplate;
	NSString *MADMessageDeleteItem = @"Are you sure you would like to delete %@ "
									 @"item?  This action is final.";
	
	messageTemplate = itemCount > 1 ?
				NSLocalizedString(MADMessageDeleteItemsPlural, @"Delete message template (plural)") :
				NSLocalizedString(MADMessageDeleteItem, @"Delete message template (singular)");
	NSString *message = [NSString stringWithFormat:messageTemplate, number];
	id alert = [UIAlertController alertControllerWithTitle: title
												   message: message
											preferredStyle: UIAlertControllerStyleActionSheet];
	NSString *titleCancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
	NSString *MADTitleDeleteItemsPlural = @"Remove %@ items";
	NSString *MADTitleDeleteItem = @"Remove %@ item";
	NSString *titleDestructiveTemplate = itemCount > 1 ?
					NSLocalizedString(MADTitleDeleteItemsPlural, @"Remove %@ items (plural)") :
					NSLocalizedString(MADTitleDeleteItem, @"Remove %@ item (singular)");
	NSString *titleDestructive = [NSString stringWithFormat:titleDestructiveTemplate, number];
	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:titleCancel
														   style:UIAlertActionStyleCancel
														 handler:handlerCancel];
	UIAlertAction *actionDestructive = [UIAlertAction actionWithTitle:titleDestructive
																style:UIAlertActionStyleDestructive
															  handler:handlerConfirm];
	[alert addAction:actionCancel];
	[alert addAction:actionDestructive];
	return alert;
}

+ (instancetype)newAlertControllerRenameDocument:(void (^)(UITextField *textField))textFieldConfig
										 confirm:(void (^)(UIAlertAction *action, NSString *text))handlerConfirm
										  cancel:(void (^)(UIAlertAction *action))handlerCancel {

	id alert;
	NSString * MADTitleRenameDocument = @"Rename Document";
	NSString *MADMessageRename = @"Please enter a new name for the document.";
	NSString *MADButtonRename = @"Rename";
	NSString *title = NSLocalizedString(MADTitleRenameDocument, MADTitleRenameDocument);
	NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
	NSString *rename = NSLocalizedString(MADButtonRename, MADButtonRename);
	NSString *message = NSLocalizedString(MADMessageRename, MADMessageRename);
	UIAlertAction *actionCancel, *actionDefault;
	UITextField *textField;
	NSString *text;
	
	alert = [UIAlertController alertControllerWithTitle: title
												message: message
										 preferredStyle: UIAlertControllerStyleAlert];
	
	[alert addTextFieldWithConfigurationHandler:textFieldConfig];
	textField = ((MADAlertController *)alert).textFields.firstObject;
	text = textField.text.copy;
	
	actionDefault = [UIAlertAction actionWithTitle: rename
											 style: UIAlertActionStyleDefault
										   handler: ^(UIAlertAction *action) {
											   handlerConfirm(action, text);
										   }];
	
	actionCancel = [UIAlertAction actionWithTitle: cancel
											style: UIAlertActionStyleCancel
										  handler: handlerCancel];
	

	[alert addAction:actionDefault];
	[alert addAction:actionCancel];
	return alert;
}

+ (instancetype)newAlertControllerErrorValidationFilename {
	NSString *MADTitleErrorValidation = @"Validation Error";
	NSString *MADMessageErrorValidFileName = @"Filename not valid.";
	NSString *title = NSLocalizedString(MADTitleErrorValidation, MADTitleErrorValidation);
	NSString *message = NSLocalizedString(MADMessageErrorValidFileName, MADMessageErrorValidFileName);
	id alert = [UIAlertController alertControllerWithTitle: title
												   message: message
											preferredStyle: UIAlertControllerStyleAlert];
	
	NSString *dismiss = NSLocalizedString(MADTitleButtonDismiss, MADTitleButtonDismiss);
	UIAlertAction *ok = [UIAlertAction actionWithTitle: dismiss
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction:ok];
	return alert;
}

+ (instancetype)newAlertControllerErrorFileExist {
	NSString *MADTitleErrorFileExist = @"File Exist";
	NSString *MADMessageErrorFileExist = @"File already exist. Please choose a new name.";
	NSString *title = NSLocalizedString(MADTitleErrorFileExist, MADTitleErrorFileExist);
	NSString *message = NSLocalizedString(MADMessageErrorFileExist, MADMessageErrorFileExist);
	id alert = [UIAlertController alertControllerWithTitle: title
												   message: message
											preferredStyle: UIAlertControllerStyleAlert];
	NSString *dismiss = NSLocalizedString(MADTitleButtonDismiss, MADTitleButtonDismiss);
	UIAlertAction *ok = [UIAlertAction actionWithTitle: dismiss
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction:ok];
	return alert;
}

+ (instancetype)newAlertControllerErrorEmptyQuery {
	NSString *MADTitleEmptyQuery = @"Empty Query";
	NSString *MADMessageEmptyQuery = @"Add tables to the query and data fields to "
									 @"the designer to generate a query.";
	NSString *title = NSLocalizedString(MADTitleEmptyQuery, MADTitleEmptyQuery);
	NSString *message = NSLocalizedString(MADMessageEmptyQuery, MADMessageEmptyQuery);
	NSString *buttonTitle = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	
	id alert = [UIAlertController alertControllerWithTitle: title
												   message: message
											preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *ok = [UIAlertAction actionWithTitle: buttonTitle
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction: ok];
	return alert;
}

+ (instancetype)newAlertControllerError:(NSError *)error {
	NSString *title = error.localizedDescription.copy ?: @"";
	NSString *messageStart = error.localizedFailureReason.copy ?: @"";
	NSString *localizedRecoverySuggestion = error.localizedRecoverySuggestion.copy ?: @"";
	NSString *message = [messageStart stringByAppendingString:localizedRecoverySuggestion];
	return [self newAlertControllerErrorDisplayErrorWithTitle: title
													  message: message
												andCompletion: nil];
}

+ (instancetype)newAlertControllerErrorDisplayErrorWithTitle:(NSString *)title
													 message:(NSString *)message
											   andCompletion:(void (^)(UIAlertAction *action))handlerContinue {
	NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	id alertController = [UIAlertController alertControllerWithTitle: title
															 message: message
													  preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle: ok
													   style: UIAlertActionStyleDefault
													 handler: handlerContinue];
	[alertController addAction:actionOK];
	return alertController;
	
}

+ (instancetype)newAlertControllerNofityTransactionComplete {
	NSString *MADTitleTransactionComplete = @"Transaction Complete";
	NSString *MADMessageSoftwareActivated = @"Software activated.";
	NSString *title = NSLocalizedString(MADTitleTransactionComplete, MADTitleTransactionComplete);
	NSString *message = NSLocalizedString(MADMessageSoftwareActivated, MADMessageSoftwareActivated);
	NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
	id alert = [UIAlertController alertControllerWithTitle: title
												   message: message
											preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionOK = [UIAlertAction actionWithTitle: ok
													   style: UIAlertActionStyleDefault
													 handler: nil];
	[alert addAction:actionOK];
	return alert;
}

/*+ (void)configureTextFieldForPassword:(UITextField * __autoreleasing *)textField {
	UILabel *password = [[UILabel alloc] init];
	password.textColor = [UIColor lightGrayColor];
	password.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	password.text = NSLocalizedString(@"Password: ", @"Password: ");
	[password sizeToFit];
	(*textField).leftView = password;
	(*textField).secureTextEntry = YES;
	(*textField).leftViewMode = UITextFieldViewModeAlways;
	(*textField).text = @"";
	(*textField).autocapitalizationType = UITextAutocapitalizationTypeNone;
	(*textField).clearButtonMode = UITextFieldViewModeAlways;
}

+ (void)configureTextFieldForUsername:(UITextField * __autoreleasing *)textField {
	UILabel *username = [[UILabel alloc] init];
	username.textColor = [UIColor lightGrayColor];
	username.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	username.text = NSLocalizedString(@"Username: ", @"Username: ");
	[username sizeToFit];
	(*textField).leftView = username;
	(*textField).secureTextEntry = NO;
	(*textField).leftViewMode = UITextFieldViewModeAlways;
	(*textField).text = @"";
	(*textField).autocapitalizationType = UITextAutocapitalizationTypeNone;
	(*textField).clearButtonMode = UITextFieldViewModeAlways;
}*/

@end
