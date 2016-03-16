//
//  MADKeyChainGetCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainGetCredentials.h"
#import <MAD/MADCredential.h>
#import <MAD/MTKeyChain.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UILabel.h>

static NSString * const MADTitleCredentials            = @"Credentials";
static NSString * const MADMessageCredentials          = @"Please enter your credentials.";

static NSString * const MADTitlePassword               = @"Password";
static NSString * const MADMessagePassword             = @"Please enter your password.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADKeyChainGetCredentials()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, strong) UIAlertController *alertController;

    @property (nonatomic, copy) NSString *key;
    @property (nonatomic, copy, readwrite) MADCredential *credential;

@end

@implementation MADKeyChainGetCredentials

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

#pragma mark - Operation

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController {
    if (self = [super init]) {
        self.viewController = viewController;
        self.key = key.copy;
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
    
    const char PromptForUsernameAndPassword = 1;
    const char PromptForPassword = 2;
    const char PromptForNothing = 3;
    
    CFDataRef queryUsernameData = NULL, queryPasswordData = NULL;

    //Read username and password.
    NSDictionary *queryUsername = [MTKeyChain queryUsernameDefination:self.key];
    OSStatus queryStatusUsername = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    
    NSDictionary *queryPassword = [MTKeyChain queryPasswordDefination:self.key];
    OSStatus queryStatusPassword = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
    
    char status = PromptForUsernameAndPassword;
    if (queryStatusUsername == errSecSuccess) {
        status = queryStatusPassword == errSecSuccess ? PromptForNothing : PromptForPassword;
    }
    
    //Sanity check the data
    if (status == PromptForNothing) {
        if (queryUsernameData == NULL || queryPasswordData == NULL)  status = PromptForUsernameAndPassword;
    } else if (status == PromptForPassword && queryPasswordData == NULL) {
        status = PromptForUsernameAndPassword;
    }
    
    switch (status) {
            
        case PromptForNothing: {

            NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData encoding: NSUTF8StringEncoding];
            NSString *password = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryPasswordData encoding: NSUTF8StringEncoding];
            MADCredential *c = [[MADCredential alloc] initWithUsername:username andPassword:password];
            self.credential = c;
            self.source = keychain;
            [self setStateFinished];
            break;
        }
            
        case PromptForPassword: {
            
            NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData
                                                       encoding:NSUTF8StringEncoding];
            [self promptForPasswordGivenUsername: username];
            break;
        }
        case PromptForUsernameAndPassword: {
            
            [self promptForUsernameAndPassword];
            break;
        }
        default:
            [self setStateError];
            break;
    }
}

- (void)promptForUsernameAndPassword {

    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);    
    
    UIAlertController *alertController = self.alertController;

    void (^ __nullable actionContinue)(UIAlertAction *action) = ^(UIAlertAction *action) {
        MADCredential *c = [[MADCredential alloc] initWithUsername: ((UITextField *)alertController.textFields.firstObject).text
                                                       andPassword: ((UITextField *)[alertController.textFields objectAtIndex:1]).text];
        self.credential = c;
        self.source = credential_prompt;
        [self setStateFinished];
    };
    
    void (^ __nullable actionCancel)(UIAlertAction *action) = ^(UIAlertAction *action) {
        self.source = none;
        [self setStateUserCancelled];
    };
    
    void (^ __nullable actionTextFieldWithConfigurationUsername)(UITextField *textField) = ^(UITextField *textField) {
        [MADKeyChainGetCredentials configureTextFieldForUsername:&textField];
        textField.delegate = self;
    };
    
    void (^ __nullable actionTextFieldWithConfigurationPassword)(UITextField *textField) = ^(UITextField *textField) {
        [MADKeyChainGetCredentials configureTextFieldForPassword:&textField];
        textField.delegate = self;
    };
    
    UIAlertAction *actionAlertKk = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: actionContinue];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: actionCancel];
    
    [alertController addAction:actionAlertKk];
    [alertController addAction:actionAlertCancel];
    
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationUsername];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationPassword];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = self.viewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: alertController animated: YES completion: nil];
    }];
    
}

- (void)promptForPasswordGivenUsername:(NSString *)username {
    
    NSString *title = NSLocalizedString(MADTitlePassword, MADTitlePassword);
    NSString *message = NSLocalizedString(MADMessagePassword, MADMessagePassword);
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    
    void (^ __nullable actionContinue)(UIAlertAction *action) = ^(UIAlertAction *action) {
        MADCredential *c = [[MADCredential alloc] initWithUsername: username
                                                       andPassword: ((UITextField *)alertController.textFields.firstObject).text];
        self.credential = c;
        self.source = password_prompt;
        [self setStateFinished];
    };
    
    void (^ __nullable actionCancel)(UIAlertAction *action) = ^(UIAlertAction *action) {
        self.credential = nil;
        self.source = none;
        [self setStateUserCancelled];
    };
    
    void (^ __nullable actionTextFieldWithConfiguration)(UITextField *textField) = ^(UITextField *textField) {
        textField.delegate = self;
    };

    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: actionContinue];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: actionCancel];
    [alertController addAction:actionAlertOK];
    [alertController addAction:actionAlertCancel];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfiguration];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = self.viewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: alertController animated: YES completion: nil];
    }];
    
}

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

+ (void)configureTextFieldForUsername:(UITextField * __autoreleasing *)textField {
    UILabel *username = [[UILabel alloc] init];
    username.textColor = [UIColor lightGrayColor];
    username.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    username.text = NSLocalizedString(@"Username: ", @"Username: ");
    [username sizeToFit];
    (*textField).leftView = username;
    (*textField).secureTextEntry = NO;
    (*textField).leftViewMode = UITextFieldViewModeAlways;
    (*textField).text = @"";
    (*textField).autocapitalizationType = UITextAutocapitalizationTypeNone;
    (*textField).clearButtonMode = UITextFieldViewModeAlways;
}

@end
