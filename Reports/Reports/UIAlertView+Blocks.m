//
//  UIAlertView+Blocks.m
//  Reports
//
//  Created by Michael Thomason on 11/3/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//
/*
#import "UIAlertView+Blocks.h"

@implementation UIAlertView (Blocks)

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
   otherButtonTitle:(NSArray *)otherButtons
          onDismiss:(DismissBlock)dismissed
           onCancel:(CancelBlock)cancelled {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message
                                                   delegate:[self self]
                                          cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    for (NSString *buttonTitle in otherButtons) {
        [alert addButtonWithTitle: buttonTitle];
    }
    [alert show];
    return alert;
    
    
}

+ (UIAlertView *)showAlertViewWithTitle:(NSString *)title
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                       otherButtonTitle:(NSArray *)otherButtons
                              onDismiss:(DismissBlock)dismissed
                               onCancel:(CancelBlock)cancelled {
    
    //[cancelBlock release];
    self.cancelBlock = [cancelled copy];
    
    dismissBlock = [dismissed copy];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message
                                                   delegate:[self self]
                                          cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    for (NSString *buttonTitle in otherButtons) {
        [alert addButtonWithTitle: buttonTitle];
    }
    [alert show];
    return [alert autorelease];
}

+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView cancelButtonIndex]) {
        _cancelBlock();
    } else {
        _dismissBlock(buttonIndex - 1);
    }
    
    [_cancelBlock autorelease];
    [_dismissBlock autorelease];
}

@end
*/