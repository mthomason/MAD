//
//  UIAlertController+Constructors.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExtensions_UIAlertController_Constructors_h
#define MADExtensions_UIAlertController_Constructors_h

#import <UIKit/UIAlertController.h>

@interface UIAlertController (Constructors)

    + (instancetype)newAlertControlerNotifyCloudSignOut:(void (^)(UIAlertAction *action))handler;
    + (instancetype)newAlertControllerPromptStorageOptionLocal:(void (^)())handlerLocal
                                                         cloud:(void (^)())handlerCloud;
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

    + (instancetype)deleteItems:(NSUInteger)itemCount
                        confirm:(void (^)(UIAlertAction *action))handlerConfirm
                         cancel:(void (^)(UIAlertAction *action))handlerCancel;

    + (instancetype)renameDocument:(void (^)(UITextField *textField))textFieldConfig
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
                               cancel:(void (^)())handlerCancel;

    + (instancetype)newAlertControllerPromptForPasswordGivenUsername:(NSString *)username
                                          password:(void (^)(UITextField *textField))passwordSetup
                                            submit:(void (^)(NSString *password))handlerContinue
                                            cancel:(void (^)())handlerCancel;


@end

#endif
