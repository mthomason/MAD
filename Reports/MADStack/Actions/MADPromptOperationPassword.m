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
#import "MADMutualExclusive.h"
#import "MADDefer.h"

static NSString * const MADTitlePassword               = @"Password";
static NSString * const MADMessagePassword             = @"Please enter your password.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADPromptOperationPassword ()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;

    @property (nonatomic, readwrite, assign) bool alertDisplayed;

    @property (nonatomic, readwrite, assign) MADCredentialSource source;
    @property (nonatomic, readwrite, copy) NSString *passwordKey;
    @property (nonatomic, readwrite, copy) NSString *password;
    @property (nonatomic, readwrite, assign) bool gotPassword;

    @property (nonatomic, readwrite, assign) bool bypass;
    @property (nonatomic, readwrite, assign) bool userContinue;


    @property (nonatomic, strong, readwrite) NSString *username;

@end

@implementation MADPromptOperationPassword

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (NSString *)key {
    return self.passwordKey;
}

- (NSString *)value {
    return self.password;
}

- (bool)success {
    return self.gotPassword;
}

- (MADKeyChainReadOperationTypes)readOperationType { return MADKeyChainReadOperationTypePassword; }

- (instancetype)initWithPasswordKey:(NSString *)passwordKey andViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
        _passwordKey = passwordKey.copy;
        _source = none;
        _alertDisplayed = false;
        _bypass = false;
        _userContinue = false;

        _viewController = viewController;
        MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        [self addCondition:condition];

    }
    return self;
}

- (NSString *)valueForKey:(NSString *)key {
    return [key isEqualToString:self.passwordKey] ? self.password : nil;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    NSString *title = NSLocalizedString(MADTitlePassword, MADTitlePassword);
    NSString *message = NSLocalizedString(MADMessagePassword, MADMessagePassword);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title message: message preferredStyle: UIAlertControllerStyleAlert];
    
    void (^ __nullable actionTextFieldWithConfiguration)(UITextField *textField) = ^(UITextField *textField) {
        [MADTextField configureTextFieldForPassword:&textField];
        textField.delegate = self;
    };
    
    MADPromptOperationPassword * __weak weakself = self;

    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action) {
        MADPromptOperationPassword *sself = weakself;
        [sself finish: true password: ((UITextField *)alertController.textFields.firstObject).text];
    }];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel style: UIAlertActionStyleCancel handler: ^(UIAlertAction *action) {
        MADPromptOperationPassword * sself = weakself;
        sself.alertDisplayed = true;
        [sself userCancel];
    }];
    
    [alertController addAction:actionAlertOK];
    [alertController addAction:actionAlertCancel];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfiguration];

    self.alertDisplayed = true;

    UIViewController * __weak wViewController = self.viewController;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = wViewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: alertController animated: YES completion:^{ }];
    }];

}

- (void)finish:(bool)success password:(NSString *)password {
    self.alertDisplayed = true;
    self.source = password_prompt;
    self.userContinue = true;
    self.password = password;
    self.gotPassword = true;
    self.result = true;
    madDefer(^{
        [self performSelectorInBackground:@selector(finish) withObject:nil];
    });
}

- (void)userCancel {
    self.userContinue = false;
    self.password = nil;
    self.result = false;
    self.gotPassword = false;
    madDefer(^{
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
