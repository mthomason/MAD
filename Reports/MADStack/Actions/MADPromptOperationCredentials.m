//
//  MADPromptOperationCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptOperationCredentials.h"
#import <UIKit/UIAlertController.h>
#import <UIKit/UITextField.h>
#import <UIKit/UILabel.h>
#import <MAD/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>

#import <MADCocoaExtensions/MADTextField.h>
#import "MADKeyChainOperationGet.h"
#import "MADMutualExclusive.h"
#import "MADDefer.h"

#import <os/log.h>

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
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithUsernameKey:(NSString *)usernameKey passwordKey:(NSString *)passwordKey
                                                      andViewController:(UIViewController *)viewController {

    if (self = [super init]) {

        _usernameKey = usernameKey.copy;
        _passwordKey = passwordKey.copy;
        _viewController = viewController;
        _source = MADCredentialSourceNone;
        _result = NO;
        _displayingPrompt = NO;
        _bypass = NO;
        _gotCredentials = NO;
        //MADMutualExclusiveCondition *condition = [MADMutualExclusiveCondition newMutualExclusiveConditionAlertMutex];
        //[self addCondition:condition];
        self.identifier = self.hash;
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
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);

    if (self.cancelled) {
        return [self finish];
    }

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
    
    void (^ __nullable actionTextFieldWithConfigurationUsername)(UITextField *textField);
    void (^ __nullable actionTextFieldWithConfigurationPassword)(UITextField *textField);
    
    MADPromptOperationCredentials * __weak weakself = self;
    
    UIAlertAction *actionAlertOK = [UIAlertAction actionWithTitle: ok style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action) {
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, "OK");
        MADPromptOperationCredentials *strongself = weakself;
        username = ((UITextField *)alertController.textFields.firstObject).text;
        password = ((UITextField *)(alertController.textFields)[1]).text;

        MADCredential *credentials = nil;
        if (username != nil && password != nil) {
            credentials = [[MADCredential alloc] initWithUsername:username andPassword:password];
            strongself.gotCredentials = YES;
            strongself.source = MADCredentialSourceCredentialPrompt;
        }
        [strongself finish:YES credentials:credentials];
        strongself.alertDisplayed = YES;
        strongself.userContinue = success;
        strongself.credentials = credentials.copy;
        strongself.result = YES;
        defer(^{
            [strongself performSelectorInBackground:@selector(finish) withObject:nil];
        });
/*
        MADPromptOperationCredentials __weak *weakself2 = strongself;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            MADPromptOperationCredentials *strongself2 = weakself2;
            //[strongself2 finish];
            [strongself2 performSelectorInBackground:@selector(finish) withObject:nil];
         });
  */      
    }];
    
    UIAlertAction *actionAlertCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: ^(UIAlertAction *action) {
        os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, "Cancel");
        MADPromptOperationCredentials *strongself = weakself;
        password = nil; username = nil;
        success = NO;
        strongself.alertDisplayed = YES;
        strongself.userContinue = NO;
        strongself.credentials = nil;
        strongself.result = NO;
        NSError *error = [NSError errorWithDomain:NSStringFromClass([strongself class]) code:173 userInfo:nil];
        MADPromptOperationCredentials * __weak weakself2 = strongself;
                                                                  
                                                                  
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            MADPromptOperationCredentials *strongself2 = weakself2;
            [strongself2 userCancel];
            [strongself2 performSelectorInBackground:@selector(finishWithError:) withObject:error];
        });

    }];
    
    
    actionTextFieldWithConfigurationUsername = ^(UITextField *textField) {
        MADPromptOperationCredentials *strongself = weakself;
        MADTextField *textFieldFormatter = [[MADTextField alloc] init];
        textFieldFormatter.handleConfigureUsername(textField);
        textField.delegate = strongself;
    };
    
    actionTextFieldWithConfigurationPassword = ^(UITextField *textField) {
        MADPromptOperationCredentials *strongself = weakself;
        MADTextField *textFieldFormatter = [[MADTextField alloc] init];
        textFieldFormatter.handleConfigurePassword(textField);
        textField.delegate = strongself;
    };

    [alertController addAction:actionAlertOK];
    [alertController addAction:actionAlertCancel];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationUsername];
    [alertController addTextFieldWithConfigurationHandler:actionTextFieldWithConfigurationPassword];
    
    UIViewController *viewController = self.viewController;
    viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [viewController  presentViewController: alertController animated: YES completion:^{
//        [self performSelectorInBackground:@selector(finish) withObject:nil];
    }];

}

- (void)finish:(BOOL)success credentials:(MADCredential *)credentials {
    self.alertDisplayed = YES;
    self.userContinue = success;
    self.credentials = credentials.copy;
    self.result = YES;
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
    //defer(^{
        //[self performSelectorInBackground:@selector(finish) withObject:nil];
    //});
}

- (void)userCancel {
    self.alertDisplayed = YES;
    self.userContinue = NO;
    self.credentials = nil;
    self.result = NO;
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
    //defer(^{
        //NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:173 userInfo:nil];
        //[self performSelectorInBackground:@selector(finishWithError:) withObject:error];
    //});
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
