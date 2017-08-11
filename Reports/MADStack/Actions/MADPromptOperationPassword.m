//
//  MADPromptPasswordOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptOperationPassword.h"
#import <UIKit/UIAlertController.h>
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>
#import <MAD/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>
#import <MADCocoaExtensions/MADTextField.h>
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADMutualExclusive.h"
#import "MADDefer.h"

#import <os/log.h>

static NSString * const MADTitlePassword               = @"Password";
static NSString * const MADMessagePassword             = @"Please enter your password.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADPromptOperationPassword ()
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

@implementation MADPromptOperationPassword

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
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
        MADMutualExclusiveCondition *condition;
        _passwordKey = passwordKey.copy;
        _source = MADCredentialSourceNone;
        _alertDisplayed = NO;
        _bypass = NO;
        _userContinue = NO;

        _viewController = viewController;
        condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        [self addCondition:condition];

    }
    return self;
}

- (NSString *)valueForKey:(NSString *)key {
    return [key isEqualToString:self.passwordKey] ? self.password : nil;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    NSString *title = NSLocalizedString(MADTitlePassword, MADTitlePassword);
    NSString *message = NSLocalizedString(MADMessagePassword, MADMessagePassword);
    UIAlertController *alertController;
    alertController = [UIAlertController alertControllerWithTitle: title
                                                          message: message
                                                   preferredStyle: UIAlertControllerStyleAlert];
    
    void (^ __nullable actionTextFieldWithConfiguration)(UITextField *textField);
    actionTextFieldWithConfiguration = ^(UITextField *textField) {
        
        MADTextField *textFormatter = [[MADTextField alloc] init];
        textFormatter.handleConfigurePassword(textField);
        textField.delegate = self;
    };
    
    MADPromptOperationPassword * __weak weakself = self;

    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok
                                                            style: UIAlertActionStyleDefault
                                                          handler: ^(UIAlertAction *action) {
        MADPromptOperationPassword *sself = weakself;
        [sself finish: YES password: ((UITextField *)alertController.textFields.firstObject).text];
    }];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: ^(UIAlertAction *action) {
        MADPromptOperationPassword * sself = weakself;
        sself.alertDisplayed = YES;
        [sself userCancel];
    }];
    
    [alertController addAction:actionAlertOK];
    [alertController addAction:actionAlertCancel];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfiguration];

    self.alertDisplayed = YES;

    UIViewController * __weak wViewController = self.viewController;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = wViewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: alertController animated: YES completion:NULL];
    }];

}

- (void)finish:(BOOL)success password:(NSString *)password {
    self.alertDisplayed = YES;
    self.source = MADCredentialSourcePasswordPrompt;
    self.userContinue = YES;
    self.password = password;
    self.gotPassword = YES;
    self.result = YES;
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish:", __PRETTY_FUNCTION__);
    defer(^{
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish defered:", __PRETTY_FUNCTION__);
        [self performSelectorInBackground:@selector(finish) withObject:nil];
    });
}

- (void)userCancel {
    self.userContinue = NO;
    self.password = nil;
    self.result = NO;
    self.gotPassword = NO;
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "User cancel:", __PRETTY_FUNCTION__);
    defer(^{
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "User cancled defered:", __PRETTY_FUNCTION__);
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:173 userInfo:nil];
        [self performSelectorInBackground:@selector(finishWithError:) withObject:error];
    });
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
