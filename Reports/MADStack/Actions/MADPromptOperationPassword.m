//
//  MADPromptPasswordOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptOperationPassword.h"
#import <UIKit/UIAlertController.h>
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>
#import <MAD/MADCredential.h>
#import "MADTextField.h"
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"

static NSString * const MADTitlePassword               = @"Password";
static NSString * const MADMessagePassword             = @"Please enter your password.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADPromptOperationPassword ()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, strong) UIAlertController *alertController;

    @property (nonatomic, assign, readwrite) MADCredentialSource source;
    @property (nonatomic, copy, readwrite) NSString *password;

    @property (nonatomic, readwrite, assign) bool bypass;
    @property (nonatomic, readwrite, assign) bool userContinue;

@end

@implementation MADPromptOperationPassword

- (instancetype)initWithViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        self.viewController = viewController;
        self.source = none;
        
        self.bypass = false;
        self.userContinue = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)start {
    if ([self isCancelled]) {
        [self setStateCanceled];
        return;
    }
    [self setStateExecuting];

    bool promptOperationCredentialsDisplaying = false;
    bool showPrompt = false;
    bool gotUsername = false;
    bool gotPassword = false;
    for (NSOperation *dependency in self.dependencies) {
        if ([dependency isKindOfClass:[MADPromptOperationCredentials class]]) {

            if (((MADPromptOperationCredentials *)dependency).displayingPrompt) {
                promptOperationCredentialsDisplaying = true;
            }
            
        } else if ([dependency isKindOfClass:[MADKeyChainOperationGet class]]) {
            if (((MADKeyChainOperationGet *)dependency).readOperationType == username) {
                gotUsername = true;
            } else if (((MADKeyChainOperationGet *)dependency).readOperationType == password) {
                gotPassword = true;
            }
        }
    }
    
    if (promptOperationCredentialsDisplaying) {
        showPrompt = false;
    } else {
        if (gotUsername && gotPassword) {
            showPrompt = false;
        }
        if (gotUsername && !gotPassword) {
            showPrompt = true;
        }
    }

    if (!showPrompt) {
        self.bypass = true;
        [self setStateFinished];
        return;
    }
    
    NSString *title = NSLocalizedString(MADTitlePassword, MADTitlePassword);
    NSString *message = NSLocalizedString(MADMessagePassword, MADMessagePassword);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    
    __block NSString *password;
    __block bool success = false;
    
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    void (^ __nullable actionTextFieldWithConfiguration)(UITextField *textField) = ^(UITextField *textField) {
        [MADTextField configureTextFieldForPassword:&textField];
        textField.delegate = self;
    };
    
    UIAlertController * __weak wAlertController = alertController;
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: ^(UIAlertAction *action) {
                                                              password = ((UITextField *)wAlertController.textFields.firstObject).text;
                                                              success = true;
                                                          }];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: ^(UIAlertAction *action) {
                                                                  password = nil;
                                                                  success = false;
                                                              }];
    [alertController addAction:actionAlertOK];
    [alertController addAction:actionAlertCancel];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfiguration];
    
    self.alertController = alertController;
    UIAlertController * __weak weakAlertController = self.alertController;
    UIViewController * __weak wViewController = self.viewController;
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = wViewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: weakAlertController animated: YES completion:^{
            dispatch_semaphore_signal(s1);
        }];
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);

    self.userContinue = success;
    self.password = password;
    [self setStateFinished];
    
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
