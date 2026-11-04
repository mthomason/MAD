//
//  MADTextField.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADTextField.h"
#if TARGET_OS_IPHONE
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>

@interface MADTextField ()

@property (readwrite, nonatomic, copy) MADTextFieldConfigurationHandler handleConfigurePassword;
@property (readwrite, nonatomic, copy) MADTextFieldConfigurationHandler handleConfigureUsername;

@end

@implementation MADTextField

- (instancetype)init {
	if (self = [super init]) {
		self.handleConfigureUsername = ^(UITextField *textField) {
			UILabel *username = [[UILabel alloc] init];
			username.textColor = [UIColor lightGrayColor];
			username.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
			username.text = NSLocalizedString(@"Username: ", @"Label before the username field.");
			[username sizeToFit];
			textField.leftView = username;
			textField.secureTextEntry = NO;
			textField.leftViewMode = UITextFieldViewModeAlways;
			textField.text = @"";
			textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			textField.clearButtonMode = UITextFieldViewModeAlways;
		};
		self.handleConfigurePassword = ^(UITextField *textField) {
			UILabel *password = [[UILabel alloc] init];
			password.textColor = [UIColor lightGrayColor];
			password.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
			password.text = NSLocalizedString(@"Password: ", @"Label before the password field.");
			[password sizeToFit];
			textField.leftView = password;
			textField.secureTextEntry = YES;
			textField.leftViewMode = UITextFieldViewModeAlways;
			textField.text = @"";
			textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			textField.clearButtonMode = UITextFieldViewModeAlways;
			
		};
	}
	return self;
}

@end
#endif
