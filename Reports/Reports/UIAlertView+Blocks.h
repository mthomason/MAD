//
//  UIAlertView+Blocks.h
//  Reports
//
//  Created by Michael Thomason on 11/3/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Blocks)

typedef void (^DismissBlock)(int buttonIndex);
typedef void (^CancelBlock)();

+ (UIAlertView *)showAlertViewWithTitle:(NSString *)title
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                       otherButtonTitle:(NSString *)otherButtons
                              onDismiss:(DismissBlock)dismissed
                               onCancel:(CancelBlock)canceled;

@end