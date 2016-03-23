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
#import "MADMutualExclusive.h"
#import "MADAlertController.h"

static NSString * const MADTitleCredentials            = @"Credentials";
static NSString * const MADMessageCredentials          = @"Please enter your credentials.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADPromptOperationCredentials()
    <UITextFieldDelegate, MADAlertControllerAlertRemovedProtocol>

    @property (nonatomic, weak) UIViewController *viewController;

    @property (nonatomic, readwrite, assign) bool alertDisplayed;

    @property (nonatomic, assign, readwrite) MADCredentialSource source;
    @property (nonatomic, copy, readwrite) MADCredential *credentials;

    @property (nonatomic, readwrite, assign) bool bypass;
    @property (nonatomic, readwrite, assign) bool userContinue;
    @property (nonatomic, readwrite, assign) bool displayingPrompt;

    @property (nonatomic, readwrite, assign) bool gotCredentials;
    @property (nonatomic, readwrite, assign) bool result;

@end

@implementation MADPromptOperationCredentials

- (instancetype)initWithViewController:(UIViewController *)viewController {

    if (self = [super init]) {
        self.viewController = viewController;
        self.source = none;
        self.result = false;
        self.displayingPrompt = false;
        self.bypass = false;
        self.gotCredentials = false;
        [self addCondition:[MADMutualExclusiveCondition alertMutex]];
        
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    self.displayingPrompt = true;

    NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
    NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
    MADAlertController *alertController = [MADAlertController alertControllerWithTitle: title message: message
                                                                        preferredStyle: UIAlertControllerStyleAlert];
    alertController.madAlertControllerAlertRemovedDelegate = self;

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
    
    MADPromptOperationCredentials * __weak weakself = self;
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: ^(UIAlertAction *action) {
                                                              MADPromptOperationCredentials *strongself = weakself;
                                                              username = ((UITextField *)alertController.textFields.firstObject).text;
                                                              password = ((UITextField *)[alertController.textFields objectAtIndex:1]).text;

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
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *viewController = self.viewController;
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [viewController  presentViewController: alertController animated: YES completion:^{ }];
    }];
}

- (void)finish:(bool)success credentials:(MADCredential *)credentials {
    self.alertDisplayed = true;
    self.userContinue = success;
    self.credentials = credentials;
    self.result = true;
}

- (void)userCancel {
    self.alertDisplayed = true;
    self.userContinue = false;
    self.credentials = nil;
    self.result = false;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

#pragma mark - MADAlertControllerAlertRemovedProtocol

- (void)alertControllerDidDisappear:(MADAlertController *)alertController {
    alertController.madAlertControllerAlertRemovedDelegate = nil;
    [self finish];
}

@end
