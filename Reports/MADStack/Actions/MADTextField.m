//
//  MADTextField.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADTextField.h"
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>

@implementation MADTextField

+ (void)configureTextFieldForPassword:(UITextField * __autoreleasing *)textField {
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

@end
