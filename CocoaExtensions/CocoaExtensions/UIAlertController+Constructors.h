//
//  UIAlertController+Constructors.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Constructors)

+ (instancetype)addedDocument;

+ (instancetype)alertNotConfiguredForEmail;

+ (instancetype)errorEmptyQuery;

+ (instancetype)errorFileExist;

+ (instancetype)errorValidationFilename;

+ (instancetype)errorDisplayErrorWithTitle:(NSString *)title
                                   message:(NSString *)message
                             andCompletion:(void (^)(UIAlertAction *action))handlerContinue;

+ (instancetype)nofityTransactionComplete;

+ (instancetype)promotCloudSignOut:(void (^)(UIAlertAction *action))handler;

+ (instancetype)promotStorageOptionLocal:(void (^)())handlerLocal
                                   cloud:(void (^)())handlerCloud;

+ (instancetype)editLabel:(void (^)(UITextField *textField))textFieldConfig
               completion:(void (^)(UIAlertAction *action, NSString *text))completion;

+ (instancetype)deleteItems:(NSUInteger)itemCount
                    confirm:(void (^)(UIAlertAction *action))handlerConfirm
                     cancel:(void (^)(UIAlertAction *action))handlerCancel;

+ (instancetype)renameDocument:(void (^)(UITextField *textField))textFieldConfig
                       confirm:(void (^)(UIAlertAction *action, NSString *text))handlerConfirm
                        cancel:(void (^)(UIAlertAction *action))handlerCancel;

+ (instancetype)saveCredentials:(void (^)(UIAlertAction *action))handlerContinue
                         cancel:(void (^)(UIAlertAction *action))handlerCancel;

+ (instancetype)removeCredentials:(void (^)(UIAlertAction *action))handlerDestructive
                           cancel:(void (^)(UIAlertAction *action))handlerCancel;

+ (instancetype)promptForUsername:(void (^)(UITextField *textField))usernameSetup
                         password:(void (^)(UITextField *textField))passwordSetup
                           submit:(void (^)(NSString *username, NSString *password))handlerContinue
                           cancel:(void (^)())handlerCancel;

+ (instancetype)promptForPasswordGivenUsername:(NSString *)username
                                      password:(void (^)(UITextField *textField))passwordSetup
                                        submit:(void (^)(NSString *password))handlerContinue
                                        cancel:(void (^)())handlerCancel;

+ (instancetype)error:(NSError *)error;

@end
