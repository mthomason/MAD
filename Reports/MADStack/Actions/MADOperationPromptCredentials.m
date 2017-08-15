//
//  MADOperationPromptCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationPromptCredentials.h"
#import <os/log.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>
#import <MAD/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>

#import <MADCocoaExtensions/MADTextField.h>
#import "MADOperationKeyChainGet.h"
#import "MADMutualExclusive.h"

static NSString * const MADTitleCredentials            = @"Credentials";
static NSString * const MADMessageCredentials          = @"Please enter your credentials.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADOperationPromptCredentials()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;

    @property (nonatomic, copy) NSString *usernameKey;
    @property (nonatomic, copy) NSString *passwordKey;

    @property (nonatomic, readwrite, assign) BOOL alertDisplayed;

    @property (nonatomic, readwrite, assign) MADCredentialSource source;
    @property (nonatomic, readwrite, copy) MADCredential *credentials;

    @property (nonatomic, readwrite, assign) BOOL bypass;
    @property (nonatomic, readwrite, assign) BOOL userContinue;
    @property (nonatomic, readwrite, assign) BOOL displayingPrompt;

    @property (nonatomic, readwrite, assign) BOOL gotCredentials;
    @property (nonatomic, readwrite, assign) BOOL result;

@end

@implementation MADOperationPromptCredentials

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithUsernameKey:(NSString *)usernameKey
                        passwordKey:(NSString *)passwordKey
                  andViewController:(UIViewController *)viewController {

    if (self = [super init]) {

        _usernameKey = usernameKey.copy;
        _passwordKey = passwordKey.copy;
        _viewController = viewController;
        _source = MADCredentialSourceNone;
        _result = NO;
        _displayingPrompt = NO;
        _bypass = NO;
        _gotCredentials = NO;
        //MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        //[self addCondition:condition];
        self.identifier = self.hash;
    }
    return self;
}

- (NSString *)valueForKey:(NSString *)key {
    if ([key isEqualToString:self.usernameKey]) {
        return self.credentials.username;
    } else if ([key isEqualToString:self.passwordKey]) {
        return self.credentials.password;
    } else {
        return nil;
    }
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);

    if (self.cancelled) {
        return [self finish];
    }

    self.displayingPrompt = YES;


    __block NSString *password;
    __block NSString *username;
    __block BOOL success = NO;
    
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    MADOperationPromptCredentials * __weak weakself = self;
    

    
    //UIViewController * __weak weakViewController = self.viewController;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
        NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title message: message
                                                                          preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertController * __weak weakAlertController = alertController;
        
        UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action) {
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, "OK");
            MADOperationPromptCredentials *strongself = weakself;
            UIAlertController *strongAlertController = weakAlertController;
            username = ((UITextField *)strongAlertController.textFields.firstObject).text.copy;
            password = ((UITextField *)(strongAlertController.textFields)[1]).text.copy;
            
            MADCredential *credentials = nil;
            if (username != nil && password != nil) {
                credentials = [[MADCredential alloc] initWithUsername:username andPassword:password];
                strongself.gotCredentials = YES;
                strongself.source = MADCredentialSourceCredentialPrompt;
            }
            strongself.alertDisplayed = YES;
            strongself.userContinue = YES;
            success = YES;
            strongself.credentials = credentials.copy;
            strongself.result = YES;
            for (UITextField *field in strongAlertController.textFields) {
                field.delegate = nil;
            }
            [strongself performSelector:@selector(finish)];
            strongAlertController = nil;
        }];
        
        UIAlertAction *actionAlertCancel;
        actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                     style: UIAlertActionStyleCancel
                                                   handler: ^(UIAlertAction *action) {
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, "Cancel");
            MADOperationPromptCredentials *strongself = weakself;
            password = nil; username = nil;
            success = NO;
            strongself.alertDisplayed = YES;
            strongself.userContinue = NO;
            strongself.credentials = nil;
            strongself.result = NO;
            for (UITextField *field in weakAlertController.textFields) {
                field.delegate = nil;
            }
            NSError *error = [NSError errorWithDomain:NSStringFromClass([strongself class])
                                                 code:173 userInfo:nil];
            [strongself performSelector:@selector(finishWithError:) withObject:error];
        }];
        
        [alertController addAction:actionAlertOK];
        [alertController addAction:actionAlertCancel];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            MADOperationPromptCredentials *strongself = weakself;
            UILabel *labelUsername = [[UILabel alloc] init];
            NSString *token = @"Username: ";
            labelUsername.textColor = [UIColor lightGrayColor];
            labelUsername.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
            labelUsername.text = NSLocalizedString(token, token);
            [labelUsername sizeToFit];
            textField.leftView = labelUsername;
            textField.secureTextEntry = NO;
            textField.leftViewMode = UITextFieldViewModeAlways;
            textField.text = @"";
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.clearButtonMode = UITextFieldViewModeAlways;
            
            textField.delegate = strongself;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            MADOperationPromptCredentials *strongself = weakself;
            UILabel *passwordLabel = [[UILabel alloc] init];
            NSString *token = @"Password: ";
            passwordLabel.textColor = [UIColor lightGrayColor];
            passwordLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
            passwordLabel.text = NSLocalizedString(token, token);
            [passwordLabel sizeToFit];
            textField.leftView = passwordLabel;
            textField.secureTextEntry = YES;
            textField.leftViewMode = UITextFieldViewModeAlways;
            textField.text = @"";
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.delegate = strongself;
        }];

        
        UIViewController *viewController = self.viewController;
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [viewController  presentViewController: alertController animated: YES completion:^{
            [weakAlertController.textFields enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
                ((UILabel *)textField.leftView).textColor = textField.isFirstResponder ? [UIColor darkGrayColor] : [UIColor lightGrayColor];
                [textField.leftView setNeedsDisplay];
            }];
        }];
    }];

}

- (BOOL)alertDisplayedAffirmed {
    return self.alertDisplayed && self.userContinue;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
