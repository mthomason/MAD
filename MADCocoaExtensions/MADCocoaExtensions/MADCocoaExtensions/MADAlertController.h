//
//  MADAlertController.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADAlertController_h
#define MAD_Designer_MADAlertController_h

#import <UIKit/UIAlertController.h>

@interface MADAlertController : NSObject

+ (UIAlertController *)newAlertControllerError:(NSError *)error;
+ (UIAlertController *)newAlertControllerNofityTransactionComplete;

+ (UIAlertController *)newAlertControllerErrorDisplayErrorWithTitle:(NSString *)title
															message:(NSString *)message
													  andCompletion:(void (^)(UIAlertAction *action))handlerContinue;


+ (UIAlertController *)newAlertControllerEditLabel:(void (^)(UITextField *textField))textFieldConfig
										completion:(void (^)(UIAlertAction *action, NSString *text))completion;

+ (UIAlertController *)newAlertControllerDeleteItems:(NSUInteger)itemCount
											 confirm:(void (^)(UIAlertAction *action))handlerConfirm
											  cancel:(void (^)(UIAlertAction *action))handlerCancel;

+ (UIAlertController *)removeCredentials:(void (^)(UIAlertAction *action))handlerDestructive
								  cancel:(void (^)(UIAlertAction *action))handlerCancel;

@end

#endif
