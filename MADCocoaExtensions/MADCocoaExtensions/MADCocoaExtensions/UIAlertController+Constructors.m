//
//  UIAlertController+Constructors.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIAlertController+Constructors.h"

NSString * const MADTitleCloudSignout           = @"iCloud Sign Out";
NSString * const MADTitleNewDocument            = @"New Document";
NSString * const MADTitleChooseStorageOptions   = @"Choose Storage Option";
NSString * const MADTitleEditLabel              = @"Edit Label";
NSString * const MADTitleEmailConfigNot         = @"Alert";
NSString * const MADTitleCredentials            = @"Credentials";
NSString * const MADTitleRenameDocument         = @"Rename Document";
NSString * const MADTitleSaveCredentials        = @"Save Credentials";
NSString * const MADTitlePassword               = @"Password";
NSString * const MADTitleTransactionComplete    = @"Transaction Complete";

NSString * const MADMessageSoftwareActivated    = @"Software activated.";
NSString * const MADMessagePassword             = @"Please enter your password.";

NSString * const MADMessageSaveCredentials      = @"Would you like to save the credentials to your "
                                                    @"key chain?";
NSString * const MADMessageCredentials          = @"Please enter your credentials.";

NSString * const MADTitleRemoveCredentials      = @"Remove Saved Password";
NSString * const MADMessageRemoveCredentials    = @"Should we remove the password saved in your "
                                                    @"keychain?";

NSString * const MADMessageCloudSignout         = @"You have signed out of the iCloud account "
                                                    @"previously used to store documents. Sign "
                                                    @"back in to access those documents.";
NSString * const MADMessageNewDocument          = @"Added document.";
NSString * const MADMessageChooseStorageOptions = @"Do you want to store documents in iCloud or "
                                                    @"only on this device?";
NSString * const MADMessageEditLabel            = @"Please enter a new name for the document.";
NSString * const MADMessageEmailConfigNot       = @"Device is not configured for email.";

NSString * const MADMessageDeleteItemsPlural    = @"Are you sure you would like to delete %@ "
                                                    @"items?  This action is final.";
NSString * const MADMessageDeleteItem           = @"Are you sure you would like to delete %@ "
                                                    @"item?  This action is final.";
NSString * const MADMessageDeleteItemsComment   = @"Delete message template (plural)";
NSString * const MADMessageDeleteItemComment    = @"Delete message template (singular)";
NSString * const MADMessageRename               = @"Please enter a new name for the document.";

NSString * const MADTitleDeleteItemsPlural      = @"Remove %@ items";
NSString * const MADTitleDeleteItemsComment     = @"Remove %@ items (plural)";
NSString * const MADTitleDeleteItem             = @"Remove %@ item";
NSString * const MADTitleDeleteItemComment      = @"Remove %@ item (singular)";

NSString * const MADTitleButtonDismiss          = @"Dismiss";
NSString * const MADTitleButtonLocalOnly        = @"Local Only";
NSString * const MADTitleButtonCloud            = @"iCloud";
NSString * const MADButtonContinue              = @"Continue";
NSString * const MADButtonCancel                = @"Cancel";
NSString * const MADButtonChange                = @"Change";
NSString * const MADButtonConfirm               = @"Confirm";
NSString * const MADButtonRename                = @"Rename";
NSString * const MADButtonKeep                  = @"Keep";
NSString * const MADButtonRemove                = @"Remove";

NSString * const MADTitleErrorFileExist         = @"File Exist";
NSString * const MADMessageErrorFileExist       = @"File already exist. Please choose a new name.";

NSString * const MADTitleErrorValidation        = @"Validation Error";
NSString * const MADMessageErrorValidFileName   = @"Filename not valid.";

NSString * const MADTitleEmptyQuery             = @"Empty Query";
NSString * const MADMessageEmptyQuery           = @"Add tables to the query and data fields to "
                                                    @"the designer to generate a query.";


typedef void (^MADTextFieldConfigurationHandler)(UITextField *textField);

@implementation MADAlertController

+ (instancetype)addedDocument {
    NSString *newdoc = NSLocalizedString(MADTitleNewDocument, MADTitleNewDocument);
    NSString *addeddoc = NSLocalizedString(MADMessageNewDocument, MADMessageNewDocument);
    NSString *continueb = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    MADAlertController *alert = [self alertControllerWithTitle: newdoc
                                                       message: addeddoc
                                                preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle: continueb
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction:ok];
    return alert;
}

+ (instancetype)promptForPasswordGivenUsername:(NSString *)username
                                      password:(void (^)(UITextField *textField))passwordSetup
                                        submit:(void (^)(NSString *password))handlerContinue
                                        cancel:(void (^)())handlerCancel {
    
    NSString *title = NSLocalizedString(MADTitlePassword, MADTitlePassword);
    NSString *message = NSLocalizedString(MADMessagePassword, MADMessagePassword);
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);

    MADAlertController *alertController = [self alertControllerWithTitle: title
                                                                 message: message
                                                          preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: ^(UIAlertAction *action) {
                                                         handlerContinue(((UITextField *)alertController.textFields.firstObject).text);
                                                     }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
                                                           style: UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             handlerCancel();
                                                         }];
    [alertController addAction:actionKk];
    [alertController addAction:actionCancel];
    [alertController addTextFieldWithConfigurationHandler:passwordSetup];

    return alertController;
    
}
+ (instancetype)promptForUsername:(void (^)(UITextField *textField))usernameSetup
                         password:(void (^)(UITextField *textField))passwordSetup
                           submit:(void (^)(NSString *username, NSString *password))handlerContinue
                           cancel:(void (^)())handlerCancel {

    NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
    NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);

    MADAlertController *alertController = [self alertControllerWithTitle: title
                                                                 message: message
                                                          preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         handlerContinue(((UITextField *)alertController.textFields.firstObject).text, ((UITextField *)[alertController.textFields objectAtIndex:1]).text);
                                                     }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
                                                           style: UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             handlerCancel();
                                                         }];
    
    [alertController addAction:actionKk];
    [alertController addAction:actionCancel];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        [self configureTextFieldForUsername:&textField];
        usernameSetup(textField);
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        [self configureTextFieldForPassword:&textField];
        passwordSetup(textField);
    }];
    
    return alertController;
}

+ (instancetype)removeCredentials:(void (^)(UIAlertAction *action))handlerDestructive
                           cancel:(void (^)(UIAlertAction *action))handlerCancel {

    NSString *title = NSLocalizedString(MADTitleRemoveCredentials, MADTitleRemoveCredentials);
    NSString *message = NSLocalizedString(MADMessageRemoveCredentials, MADMessageRemoveCredentials);
    NSString *keep = NSLocalizedString(MADButtonKeep, MADButtonKeep);
    NSString *remove = NSLocalizedString(MADButtonRemove, MADButtonRemove);
    
    MADAlertController *alert = [self alertControllerWithTitle: title
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

+ (instancetype)saveCredentials:(void (^)(UIAlertAction *action))handlerContinue
                         cancel:(void (^)(UIAlertAction *action))handlerCancel {

    NSString *title = NSLocalizedString(MADTitleSaveCredentials, MADTitleSaveCredentials);
    NSString *message = NSLocalizedString(MADMessageSaveCredentials, MADMessageSaveCredentials);
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    MADAlertController *alertController = [self alertControllerWithTitle: title
                                                                 message: message
                                                          preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: handlerContinue];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
                                                           style: UIAlertActionStyleCancel
                                                         handler: handlerCancel];
    
    [alertController addAction:actionKk];
    [alertController addAction:actionCancel];
    return alertController;
}

+ (instancetype)promotCloudSignOut:(void (^)(UIAlertAction *action))handler {
    NSString *title = NSLocalizedString(MADTitleCloudSignout, MADTitleCloudSignout);
    NSString *message = NSLocalizedString(MADMessageCloudSignout, MADMessageCloudSignout);
    NSString *ok = NSLocalizedString(MADTitleButtonDismiss, MADTitleButtonDismiss);
    MADAlertController *alertController = [self alertControllerWithTitle: title
                                                                 message: message
                                                          preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: handler];
    [alertController addAction:actionKk];
    return alertController;
}

+ (instancetype)promotStorageOptionLocal:(void (^)())handlerLocal
                                   cloud:(void (^)())handlerCloud {

    NSString *title = NSLocalizedString(MADTitleChooseStorageOptions, MADTitleChooseStorageOptions);
    NSString *message = NSLocalizedString(MADMessageChooseStorageOptions, MADMessageChooseStorageOptions);
    NSString *localOnlyActionTitle = NSLocalizedString(MADTitleButtonLocalOnly, MADTitleButtonLocalOnly);
    NSString *cloudActionTitle = NSLocalizedString(MADTitleButtonCloud, MADTitleButtonCloud);
    
    MADAlertController *storageController = [self alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *localOption = [UIAlertAction actionWithTitle:localOnlyActionTitle style:UIAlertActionStyleDefault handler:handlerLocal];
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:handlerCloud];
    [storageController addAction:cloudOption];

    return storageController;
}

+ (instancetype)editLabel:(void (^)(UITextField *textField))textFieldConfig
               completion:(void (^)(UIAlertAction *action, NSString *text))completion {
    
    NSString *title = NSLocalizedString(MADTitleEditLabel, MADTitleEditLabel);
    NSString *message = NSLocalizedString(MADMessageEditLabel, MADMessageEditLabel);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    NSString *change = NSLocalizedString(MADButtonChange, MADButtonChange);
    
    MADAlertController *alert = [self alertControllerWithTitle: title
                                                       message: message
                                                preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *actionDefault = [UIAlertAction actionWithTitle: change
                                                            style: UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              UITextField *textField = alert.textFields.firstObject;
                                                              completion(action, textField.text);
                                                          }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
                                                           style: UIAlertActionStyleCancel
                                                         handler: nil];
    
    [alert addTextFieldWithConfigurationHandler:textFieldConfig];
    
    [alert addAction:actionDefault];
    [alert addAction:actionCancel];
    return alert;
}

+ (instancetype)alertNotConfiguredForEmail {
    NSString *title = NSLocalizedString(MADTitleEmailConfigNot, MADTitleEmailConfigNot);
    NSString *message = NSLocalizedString(MADMessageEmailConfigNot, MADMessageEmailConfigNot);
    NSString *titleButton = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    MADAlertController *alert = [self alertControllerWithTitle: title
                                                       message: message
                                                preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle: titleButton
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction:ok];
    return alert;
}

+ (instancetype)deleteItems:(NSUInteger)itemCount
                    confirm:(void (^)(UIAlertAction *action))handlerConfirm
                     cancel:(void (^)(UIAlertAction *action))handlerCancel {
    
    NSNumber *selectedItemsCount = @(itemCount);
    NSString *number = [NSNumberFormatter localizedStringFromNumber: selectedItemsCount
                                                        numberStyle: NSNumberFormatterSpellOutStyle];
    NSString *title = NSLocalizedString(MADButtonConfirm, MADButtonConfirm);
    NSString *messageTemplate = itemCount > 1 ?
    NSLocalizedString(MADMessageDeleteItemsPlural, MADMessageDeleteItemsComment) :
    NSLocalizedString(MADMessageDeleteItem, MADMessageDeleteItemComment);
    NSString *message = [NSString stringWithFormat:messageTemplate, number];
    MADAlertController *alert = [self alertControllerWithTitle: title
                                                       message: message
                                                preferredStyle: UIAlertControllerStyleActionSheet];
    NSString *titleCancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    NSString *titleDestructiveTemplate = itemCount > 1 ?
    NSLocalizedString(MADTitleDeleteItemsPlural, MADTitleDeleteItemsComment) :
    NSLocalizedString(MADTitleDeleteItem, MADTitleDeleteItemComment);
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

+ (instancetype)renameDocument:(void (^)(UITextField *textField))textFieldConfig
                       confirm:(void (^)(UIAlertAction *action, NSString *text))handlerConfirm
                        cancel:(void (^)(UIAlertAction *action))handlerCancel {

    NSString *title = NSLocalizedString(MADTitleRenameDocument, MADTitleRenameDocument);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    NSString *rename = NSLocalizedString(MADButtonRename, MADButtonRename);
    NSString *message = NSLocalizedString(MADMessageRename, MADMessageRename);
    
    MADAlertController *alert = [self     alertControllerWithTitle: title
                                                           message: message
                                                    preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *actionDefault = [UIAlertAction actionWithTitle: rename
                                                            style: UIAlertActionStyleDefault
                                                          handler: ^(UIAlertAction *action) {
                                                              UITextField *textField = alert.textFields.firstObject;
                                                              handlerConfirm(action, textField.text);
                                                          }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
                                                           style: UIAlertActionStyleCancel
                                                         handler: handlerCancel];
    
    [alert addTextFieldWithConfigurationHandler:textFieldConfig];
    
    [alert addAction:actionDefault];
    [alert addAction:actionCancel];
    return alert;
}

+ (instancetype)errorValidationFilename {
    NSString *title = NSLocalizedString(MADTitleErrorValidation, MADTitleErrorValidation);
    NSString *message = NSLocalizedString(MADMessageErrorValidFileName, MADMessageErrorValidFileName);
    MADAlertController *alert = [self alertControllerWithTitle: title
                                                       message: message
                                                preferredStyle: UIAlertControllerStyleAlert];
    
    NSString *dismiss = NSLocalizedString(MADTitleButtonDismiss, MADTitleButtonDismiss);
    UIAlertAction *ok = [UIAlertAction actionWithTitle: dismiss
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction:ok];
    return alert;
}

+ (instancetype)errorFileExist {
    NSString *title = NSLocalizedString(MADTitleErrorFileExist, MADTitleErrorFileExist);
    NSString *message = NSLocalizedString(MADMessageErrorFileExist, MADMessageErrorFileExist);
    MADAlertController *alert = [self alertControllerWithTitle: title
                                                       message: message
                                                preferredStyle: UIAlertControllerStyleAlert];
    NSString *dismiss = NSLocalizedString(MADTitleButtonDismiss, MADTitleButtonDismiss);
    UIAlertAction *ok = [UIAlertAction actionWithTitle: dismiss
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction:ok];
    return alert;
}

+ (instancetype)errorEmptyQuery {
    NSString *title = NSLocalizedString(MADTitleEmptyQuery, MADTitleEmptyQuery);
    NSString *message = NSLocalizedString(MADMessageEmptyQuery, MADMessageEmptyQuery);
    NSString *buttonTitle = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    
    MADAlertController *alert = [self alertControllerWithTitle: title
                                                       message: message
                                                preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle: buttonTitle
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction: ok];
    return alert;
}
+ (instancetype)error:(NSError *)error {
    NSString *title = error.localizedDescription ?: @"";
    NSString *messageStart = error.localizedFailureReason ?: @"";
    NSString *message = [messageStart stringByAppendingString:error.localizedRecoverySuggestion ?: @""];
    return [self errorDisplayErrorWithTitle:title message:message andCompletion:nil];
}

+ (instancetype)errorDisplayErrorWithTitle:(NSString *)title
                                   message:(NSString *)message
                             andCompletion:(void (^)(UIAlertAction *action))handlerContinue {
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    MADAlertController *alertController = [self alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: handlerContinue];
    [alertController addAction:actionOK];
    return alertController;
    
}

+ (instancetype)nofityTransactionComplete {
    NSString *title = NSLocalizedString(MADTitleTransactionComplete, MADTitleTransactionComplete);
    NSString *message = NSLocalizedString(MADMessageSoftwareActivated, MADMessageSoftwareActivated);
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    MADAlertController *alert = [self alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle: ok
                                                       style: UIAlertActionStyleDefault
                                                     handler: nil];
    [alert addAction:actionOK];
    return alert;
}

+ (void)configureTextFieldForPassword:(UITextField **)textField {
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

+ (void)configureTextFieldForUsername:(UITextField **)textField {
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
}

@end
