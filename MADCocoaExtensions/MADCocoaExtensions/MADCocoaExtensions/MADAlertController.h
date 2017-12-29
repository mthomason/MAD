//
//  MADAlertController.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADAlertController_h
#define MAD_Designer_MADAlertController_h

#import <UIKit/UIAlertController.h>

@interface MADAlertController : UIAlertController

    + (instancetype)newAlertControllerNotifyCloudSignOut:(void (^)(UIAlertAction *action))handler;
    + (instancetype)newAlertControllerAddedDocument;
    + (instancetype)newAlertControllerNotConfiguredForEmail;
    + (instancetype)newAlertControllerErrorEmptyQuery;
    + (instancetype)newAlertControllerErrorFileExist;
    + (instancetype)newAlertControllerErrorValidationFilename;
    + (instancetype)newAlertControllerError:(NSError *)error;
    + (instancetype)newAlertControllerNofityTransactionComplete;

    + (instancetype)newAlertControllerErrorDisplayErrorWithTitle:(NSString *)title
                                       message:(NSString *)message
                                 andCompletion:(void (^)(UIAlertAction *action))handlerContinue;


    + (instancetype)newAlertControllerEditLabel:(void (^)(UITextField *textField))textFieldConfig
                                     completion:(void (^)(UIAlertAction *action, NSString *text))completion;

    + (instancetype)newAlertControllerDeleteItems:(NSUInteger)itemCount
                                          confirm:(void (^)(UIAlertAction *action))handlerConfirm
                                           cancel:(void (^)(UIAlertAction *action))handlerCancel;

    + (instancetype)newAlertControllerRenameDocument:(void (^)(UITextField *textField))textFieldConfig
                           confirm:(void (^)(UIAlertAction *action, NSString *text))handlerConfirm
                            cancel:(void (^)(UIAlertAction *action))handlerCancel;

    + (instancetype)newAlertControllerSaveCredentials:(void (^)(UIAlertAction *action))handlerContinue
                                               cancel:(void (^)(UIAlertAction *action))handlerCancel;

    + (instancetype)removeCredentials:(void (^)(UIAlertAction *action))handlerDestructive
                               cancel:(void (^)(UIAlertAction *action))handlerCancel;

    + (instancetype)newAlertControllerPromptForUsername:(void (^)(UITextField *textField))usernameSetup
                             password:(void (^)(UITextField *textField))passwordSetup
                               submit:(void (^)(NSString *username,
                                                NSString *password))handlerContinue
                               cancel:(void (^)(void))handlerCancel;

    + (instancetype)newAlertControllerPromptForPasswordGivenUsername:(NSString *)username
                                          password:(void (^)(UITextField *textField))passwordSetup
                                            submit:(void (^)(NSString *password))handlerContinue
                                            cancel:(void (^)(void))handlerCancel;

@end

#endif
