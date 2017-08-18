//
//  MADPromptPasswordOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationPromptPassword.h"
#import <os/log.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>
#import <MADFoundation/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>
#import <MADCocoaExtensions/MADTextField.h>
#import <MAD/MADOperationKeyChainGet.h>
#import "MADOperationPromptCredentials.h"
#import "MADMutualExclusive.h"

static NSString * const MADTitlePassword               = @"Password";
static NSString * const MADMessagePassword             = @"Please enter your password.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADOperationPromptPassword ()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;

    @property (nonatomic, readwrite, assign) BOOL alertDisplayed;
    @property (nonatomic, readwrite, assign) BOOL gotPassword;

    @property (nonatomic, readwrite, assign) BOOL bypass;
    @property (nonatomic, readwrite, assign) BOOL userContinue;

    @property (nonatomic, readwrite, assign) MADCredentialSource source;

    @property (nonatomic, readwrite, copy) NSString *passwordKey;
    @property (nonatomic, readwrite, copy) NSString *password;
    @property (nonatomic, readwrite, strong) NSString *username;

@end

@implementation MADOperationPromptPassword

- (void)dealloc {
    //os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (NSString *)key {
    return self.passwordKey;
}

- (NSString *)value {
    return self.password;
}

- (BOOL)success {
    return self.gotPassword;
}

- (MADKeyChainReadOperationTypes)readOperationType { return MADKeyChainReadOperationTypePassword; }

- (instancetype)initWithPasswordKey:(NSString *)passwordKey
                  andViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
        //MADMutualExclusiveCondition *condition;
        _passwordKey = passwordKey.copy;
        _source = MADCredentialSourceNone;
        _alertDisplayed = NO;
        _bypass = NO;
        _userContinue = NO;

        _viewController = viewController;
        self.identifier = self.hash;
        //condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        //[self addCondition:condition];

    }
    return self;
}

- (NSString *)valueForKey:(NSString *)key {
    return [key isEqualToString:self.passwordKey] ? self.password : nil;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);

    if (self.cancelled) {
        return [self finish];
    }

    NSString *title = NSLocalizedString(MADTitlePassword, MADTitlePassword);
    NSString *message = NSLocalizedString(MADMessagePassword, MADMessagePassword);
    UIAlertController *alertController;
    alertController = [UIAlertController alertControllerWithTitle: title
                                                          message: message
                                                   preferredStyle: UIAlertControllerStyleAlert];
    
    void (^ __nullable actionTextFieldWithConfiguration)(UITextField *textField);

    MADOperationPromptPassword * __weak weakself = self;

    actionTextFieldWithConfiguration = ^(UITextField *textField) {
        
        MADTextField *textFormatter = [[MADTextField alloc] init];
        textFormatter.handleConfigurePassword(textField);
        textField.delegate = weakself;
    };
    
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    UIAlertController * __weak weakAlertController = alertController;
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: ^(UIAlertAction *action) {
        UIAlertController *strongAlertController = weakAlertController;
        MADOperationPromptPassword *sself = weakself;
        sself.alertDisplayed = YES;
        sself.source = MADCredentialSourcePasswordPrompt;
        sself.userContinue = YES;
        sself.password = ((UITextField *)strongAlertController.textFields.firstObject).text.copy;
        sself.gotPassword = YES;
        sself.result = YES;
        for (UITextField *field in strongAlertController.textFields) {
            field.delegate = nil;
        }
        [sself performSelector:@selector(finish)];
                                                              
    }];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: ^(UIAlertAction *action) {
        UIAlertController *strongAlertController = weakAlertController;
        MADOperationPromptPassword *sself = weakself;
        sself.alertDisplayed = YES;
        sself.userContinue = NO;
        sself.password = nil;
        sself.result = NO;
        sself.gotPassword = NO;
        for (UITextField *field in strongAlertController.textFields) {
            field.delegate = nil;
        }
        NSError *error = [NSError errorWithDomain:NSStringFromClass([sself class]) code:173 userInfo:nil];
        [sself performSelector:@selector(finishWithError:) withObject:error];
    }];
    
    [alertController addAction:actionAlertOK];
    [alertController addAction:actionAlertCancel];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfiguration];

    self.alertDisplayed = YES;

    UIViewController * __weak wViewController = self.viewController;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIAlertController *strongAlertController = weakAlertController;
        UIViewController *topViewController = wViewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: strongAlertController animated: YES completion:NULL];
    }];

}

- (BOOL)alertDisplayedAffirmed {
    return self.alertDisplayed && self.userContinue;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
