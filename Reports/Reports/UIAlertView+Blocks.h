//
//  UIAlertView+Blocks.h
//  Reports
//
//  Created by Michael Thomason on 11/3/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//
/*
#import <UIKit/UIKit.h>

typedef void (^DismissBlock)(int buttonIndex);
typedef void (^CancelBlock)();

@interface UIAlertView (Blocks) <UIAlertViewDelegate>

@property (nonatomic, retain) UIAlertView *alertView;
@property (copy) DismissBlock dismissBlock;
@property (copy) CancelBlock cancelBlock;


+ (UIAlertView *)showAlertViewWithTitle:(NSString *)title
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                       otherButtonTitle:(NSArray *)otherButtons
                              onDismiss:(DismissBlock)dismissed
                               onCancel:(CancelBlock)canceled;

@end*/