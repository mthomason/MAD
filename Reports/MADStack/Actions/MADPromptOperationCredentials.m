//
//  MADPromptOperationCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptOperationCredentials.h"
#import <UIKit/UIAlertController.h>
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>
#import <MAD/MADCredential.h>
#import "MADTextField.h"

static NSString * const MADTitleCredentials            = @"Credentials";
static NSString * const MADMessageCredentials          = @"Please enter your credentials.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADPromptOperationCredentials()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, strong) UIAlertController *alertController;

    @property (nonatomic, assign, readwrite) MADCredentialSource source;
    @property (nonatomic, copy, readwrite) MADCredential *credentials;

@end

@implementation MADPromptOperationCredentials

- (instancetype)initWithViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        self.viewController = viewController;
        self.source = none;
        
        NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
        NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                                 message: message
                                                                          preferredStyle: UIAlertControllerStyleAlert];
        self.alertController = alertController;
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
    __block NSString *username;
    __block bool success = false;
    
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [self promptForCredentials:^(UIAlertAction *action) {
        UIAlertController * __strong sAlertController = wAlertController;
        username = ((UITextField *)[sAlertController.textFields objectAtIndex:1]).text;
        password = ((UITextField *)sAlertController.textFields.firstObject).text;
        success = true;
    } cancelHandler:^(UIAlertAction *action) {
        password = nil; username = nil;
        success = false;
    } completion:^{
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    
    if (success && username != nil && password != nil) {
        
        MADCredential *credentials = [[MADCredential alloc] initWithUsername:username andPassword:password];
        self.credentials = credentials;
        
        [self setStateFinished];
        
    } else {
        [self setStateCanceled];
    }
    
}

- (void)promptForCredentials:(void (^ __nullable)(UIAlertAction *action))actionContinue
               cancelHandler:(void (^ __nullable)(UIAlertAction *action))actionCancel
                  completion:(void (^ __nullable)(void))completion {
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    void (^ __nullable actionTextFieldWithConfigurationUsername)(UITextField *textField) = ^(UITextField *textField) {
        [MADTextField configureTextFieldForUsername:&textField];
        textField.delegate = self;
    };
    
    void (^ __nullable actionTextFieldWithConfigurationPassword)(UITextField *textField) = ^(UITextField *textField) {
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
    [self.alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationUsername];
    [self.alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationPassword];
    
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
