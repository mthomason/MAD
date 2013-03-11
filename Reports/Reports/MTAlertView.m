//
//  MTAlertView.m
//  Reports
//
//  Created by Michael Thomason on 3/11/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTAlertView.h"

@interface MTAlertView ()

@property (nonatomic, retain) UIAlertView *alertView;
@property (copy) MTAlertViewDismissBlock dismissBlock;
@property (copy) MTAlertViewCancelBlock cancelBlock;

@end

@implementation MTAlertView

- (void)dealloc {
    
    [_dismissBlock release];
    [_cancelBlock release];
    [super dealloc];
}

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
   otherButtonTitle:(NSArray *)otherButtons
          onDismiss:(MTAlertViewDismissBlock)dismissed
           onCancel:(MTAlertViewCancelBlock)cancelled {

    self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    if (self) {
        [self setCancelBlock:[cancelled copy]];
        [self setDismissBlock:[dismissed copy]];
        for (NSString *buttonTitle in otherButtons) {
            [self addButtonWithTitle: buttonTitle];
        }
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView cancelButtonIndex]) {
        if ([self cancelBlock] != nil) {
            self.cancelBlock();
        }
    } else {
        if ([self dismissBlock] != nil) {
            self.dismissBlock(buttonIndex - 1);
        }
    }
}

@end
