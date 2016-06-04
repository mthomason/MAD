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
#import "MADDefer.h"

static NSString * const MADTitleCredentials            = @"Credentials";
static NSString * const MADMessageCredentials          = @"Please enter your credentials.";

static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADPromptOperationCredentials()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, copy) NSString *usernameKey;
    @property (nonatomic, copy) NSString *passwordKey;

    @property (nonatomic, readwrite, assign) BOOL alertDisplayed;

    @property (nonatomic, assign, readwrite) MADCredentialSource source;
    @property (nonatomic, copy, readwrite) MADCredential *credentials;

    @property (nonatomic, readwrite, assign) BOOL bypass;
    @property (nonatomic, readwrite, assign) BOOL userContinue;
    @property (nonatomic, readwrite, assign) BOOL displayingPrompt;

    @property (nonatomic, readwrite, assign) BOOL gotCredentials;
    @property (nonatomic, readwrite, assign) BOOL result;

@end

@implementation MADPromptOperationCredentials

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithUsernameKey:(NSString *)usernameKey passwordKey:(NSString *)passwordKey
                                                      andViewController:(UIViewController *)viewController {

    if (self = [super init]) {

        NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
        _usernameKey = usernameKey.copy;
        _passwordKey = passwordKey.copy;
        _viewController = viewController;
        _source = none;
        _result = NO;
        _displayingPrompt = NO;
        _bypass = NO;
        _gotCredentials = NO;
        MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        [self addCondition:condition];
        
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
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    self.displayingPrompt = YES;

    NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
    NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];

    __block NSString *password;
    __block NSString *username;
    __block BOOL success = NO;
    
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
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action) {
        MADPromptOperationCredentials *strongself = weakself;
        username = ((UITextField *)alertController.textFields.firstObject).text;
        password = ((UITextField *)(alertController.textFields)[1]).text;

        MADCredential *credentials = nil;
        if (username != nil && password != nil) {
            credentials = [[MADCredential alloc] initWithUsername:username andPassword:password];
            strongself.gotCredentials = YES;
            strongself.source = credential_prompt;
        }
        [strongself finish:YES credentials:credentials];
    }];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel style: UIAlertActionStyleCancel handler: ^(UIAlertAction *action) {
        password = nil; username = nil;
        success = NO;
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

- (void)finish:(BOOL)success credentials:(MADCredential *)credentials {
    self.alertDisplayed = YES;
    self.userContinue = success;
    self.credentials = credentials;
    self.result = YES;
    defer(^{
        [self performSelectorInBackground:@selector(finish) withObject:nil];
    });
}

- (void)userCancel {
    self.alertDisplayed = YES;
    self.userContinue = NO;
    self.credentials = nil;
    self.result = NO;
    defer(^{
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
