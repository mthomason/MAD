//
//  MADTextField.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADTextField.h"
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
			NSString *token = @"Username: ";
			username.textColor = [UIColor lightGrayColor];
			username.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
			username.text = NSLocalizedString(token, token);
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
			NSString *token = @"Password: ";
			password.textColor = [UIColor lightGrayColor];
			password.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
			password.text = NSLocalizedString(token, token);
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
