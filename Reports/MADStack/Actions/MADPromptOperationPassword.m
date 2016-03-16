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

@end

@implementation MADPromptOperationPassword

- (instancetype)initWithViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        self.viewController = viewController;
        self.source = none;

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
    
    UIAlertController * __weak wAlertController = self.alertController;
    __block NSString *password;
    __block bool success = false;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [self promptForPassword:^(UIAlertAction *action) {
        password = ((UITextField *)wAlertController.textFields.firstObject).text;
        success = true;
    } cancelHandler:^(UIAlertAction *action) {
        password = nil;
        success = false;
    } completion:^{
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);

    self.password = password;
    if (success) {
        [self setStateFinished];
    } else {
        [self setStateCanceled];
    }
    
}

- (void)promptForPassword:(void (^ __nullable)(UIAlertAction *action))actionContinue
            cancelHandler:(void (^ __nullable)(UIAlertAction *action))actionCancel
               completion:(void (^ __nullable)(void))completion {
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    void (^ __nullable actionTextFieldWithConfiguration)(UITextField *textField) = ^(UITextField *textField) {
        [MADTextField configureTextFieldForPassword:&textField];
        textField.delegate = self;
    };
    
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: actionContinue];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: actionCancel];
    [self.alertController addAction:actionAlertOK];
    [self.alertController addAction:actionAlertCancel];
    [self.alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfiguration];

    UIAlertController * __weak wAlertController = self.alertController;
    UIViewController * __weak wViewController = self.viewController;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = wViewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: wAlertController animated: YES completion:completion];
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
