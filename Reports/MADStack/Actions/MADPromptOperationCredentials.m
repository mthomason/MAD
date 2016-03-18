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
#import "MADKeyChainOperationGet.h"

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

    @property (nonatomic, readwrite, assign) bool bypass;
    @property (nonatomic, readwrite, assign) bool userContinue;
    @property (nonatomic, readwrite, assign) bool displayingPrompt;

    @property (nonatomic, readwrite, assign) bool gotCredentials;

@end

@implementation MADPromptOperationCredentials

- (instancetype)initWithViewController:(UIViewController *)viewController {

    if (self = [super init]) {
    
        self.viewController = viewController;
        self.source = none;
        
        self.displayingPrompt = false;
        self.bypass = false;
        self.gotCredentials = false;
        
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    self.displayingPrompt = true;

    NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
    NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];

    __block NSString *password;
    __block NSString *username;
    __block bool success = false;
    
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
    
    MADPromptOperationCredentials *weakself = self;
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: ^(UIAlertAction *action) {
                                                              MADPromptOperationCredentials * __strong strongself = weakself;
                                                              username = ((UITextField *)strongself.alertController.textFields.firstObject).text;
                                                              password = ((UITextField *)[strongself.alertController.textFields objectAtIndex:1]).text;
                                                              

                                                              MADCredential *credentials = nil;
                                                              if (username != nil && password != nil) {
                                                                  credentials = [[MADCredential alloc] initWithUsername:username andPassword:password];
                                                                  strongself.gotCredentials = true;
                                                                  strongself.source = credential_prompt;
                                                              }
                                                              [strongself finish:true credentials:credentials];
                                       
                                                              
                                                          }];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: ^(UIAlertAction *action) {
                                                                  password = nil; username = nil;
                                                                  success = false;
                                                                  [weakself userCancel];
                                                              }];
    [alertController addAction:actionAlertOK];
    [alertController addAction:actionAlertCancel];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationUsername];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationPassword];
    
    self.alertController = alertController;
    UIAlertController * __weak weakAlertController = self.alertController;
    UIViewController * __weak wViewController = self.viewController;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = wViewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: weakAlertController animated: YES completion:^{ }];
    }];
}

- (void)finish:(bool)success credentials:(MADCredential *)credentials {
    self.userContinue = success;
    self.credentials = credentials;
    [self finish];
}

- (void)userCancel {
    self.userContinue = false;
    self.credentials = nil;
    [self finish];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
