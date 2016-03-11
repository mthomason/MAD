//
//  MADKeyChainSaveCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainSaveCredentials.h"
#import <UIKit/UIAlertController.h>
#import <UIKit/UILabel.h>
#import <MAD/MADCredential.h>
#import <MAD/MTKeyChain.h>

NSString * const MADTitleCredentials            = @"Credentials";
NSString * const MADMessageCredentials          = @"Please enter your credentials.";

NSString * const MADTitlePassword               = @"Password";
NSString * const MADMessagePassword             = @"Please enter your password.";

NSString * const MADButtonContinue              = @"Continue";
NSString * const MADButtonCancel                = @"Cancel";

typedef NS_ENUM(char, MADOperationState) {
    nonready,
    ready,
    executing,
    finished,
    error,
    cancelled,
    usercancelled
};

@interface MADKeyChainGetCredentials()
    <UITextFieldDelegate>

    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, copy) MADCredential *credential;
    @property (nonatomic, copy) NSString *key;

    @property (nonatomic, assign) MADOperationState state;

@end

@implementation MADKeyChainGetCredentials
 {
     dispatch_queue_t _stateGuardQueue;
 }

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
        _state = ready;
        _stateGuardQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (BOOL)isReady { return self.state == ready; }

- (BOOL)isAsynchronous { return YES; }

- (BOOL)isExecuting {return self.state == executing; }

- (BOOL)isFinished { return self.state == finished || self.state == error || self.state == cancelled; }

- (void)main {

    
}
/*
- (void)setOperationState:(MADOperationState)state {
        if (self->_state != state) {
            NSString *selector = nil;
            switch (state) {
                case cancelled:
                    selector = NSStringFromSelector(@selector(isFinished));
                    break;
                case executing:
                    selector = NSStringFromSelector(@selector(isExecuting));
                    break;
                case finished:
                    selector = NSStringFromSelector(@selector(isFinished));
                    break;
                case error:
                    selector = NSStringFromSelector(@selector(isFinished));
                    break;
                case usercancelled:
                    selector = NSStringFromSelector(@selector(isFinished));
                    break;
                case nonready:
                case ready:
                default:
                    break;
            }
            if (selector) {
                [self willChangeValueForKey:selector];
                self->_state = state;
                [self didChangeValueForKey:selector];
            }
            
        }

    });
}
*/
- (void)setStateCanceled {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = cancelled;
    [self didChangeValueForKey:isFinished];
}

- (void)setStateError {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = error;
    [self didChangeValueForKey:isFinished];
}

- (void)setStateFinished {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = finished;
    [self didChangeValueForKey:isFinished];
}

- (void)setStateExecuting {
    NSString *isExecuting = NSStringFromSelector(@selector(isExecuting));
    [self willChangeValueForKey:isExecuting];
    self.state = executing;
    [self didChangeValueForKey:isExecuting];
}

- (void)setStateUserCancelled {
    NSString *isFinished = NSStringFromSelector(@selector(isFinished));
    [self willChangeValueForKey:isFinished];
    self.state = usercancelled;
    [self didChangeValueForKey:isFinished];
}

- (void)start {
    
    if ([self isCancelled]) {
        [self setStateCanceled];
        return;
    }
    [self setStateExecuting];
    
    const char stateGetPassword = 1;
    const char stateGetUsernameAndPassword = 2;
    const char stateGetNothing = 3;
    
    NSInteger status;
    CFDataRef queryUsernameData = NULL, queryPasswordData = NULL;
    NSDictionary *queryUsername = [MTKeyChain queryUsernameDefination:self.key];
    NSDictionary *queryPassword = [MTKeyChain queryPasswordDefination:self.key];
    
    OSStatus queryUsernameStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    OSStatus queryPasswordStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
    
    //Check items doesn't exist
    if (queryUsernameStatus == errSecItemNotFound) {
        status = stateGetUsernameAndPassword;
    } else {
        if (queryPasswordStatus == errSecItemNotFound) {
            status = stateGetPassword;
        } else {
            status = stateGetNothing;
        }
    }
    
    //Check errors
    if (status == stateGetNothing) {
        if (queryUsernameStatus == errSecSuccess && queryUsernameData != NULL) {
            if ((queryPasswordStatus == errSecSuccess && queryPasswordData != NULL) == NO){
                status = stateGetPassword;
            }
        } else {
            status = stateGetUsernameAndPassword;
        }
    }
    
    
    switch (status) {
            
        case stateGetNothing: {

            NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData
                                                       encoding: NSUTF8StringEncoding];;
            NSString *password = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryPasswordData
                                                       encoding: NSUTF8StringEncoding];
            MADCredential *c = [[MADCredential alloc] initWithUsername:username andPassword:password];
            self.credential = c;
            [self setStateFinished];
            break;
        }
            
        case stateGetPassword: {
            
            NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData
                                                       encoding:NSUTF8StringEncoding];
            [self promptForPasswordGivenUsername: username];
            break;
        }
        case stateGetUsernameAndPassword: {
            
            [self promptForUsernameAndPassword];
            break;
        }
        default:
            [self setStateError];
            break;
    }
}

- (void)promptForUsernameAndPassword {

    NSString *title = NSLocalizedString(MADTitleCredentials, MADTitleCredentials);
    NSString *message = NSLocalizedString(MADMessageCredentials, MADMessageCredentials);
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    
    
    void (^ __nullable actionContinue)(UIAlertAction *action) = ^(UIAlertAction *action) {
        MADCredential *c = [[MADCredential alloc] initWithUsername: ((UITextField *)alertController.textFields.firstObject).text
                                                       andPassword:((UITextField *)[alertController.textFields objectAtIndex:1]).text];
        self.credential = c;
        [self setStateFinished];
    };
    
    void (^ __nullable actionCancel)(UIAlertAction *action) = ^(UIAlertAction *action) {
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
        [self setStateFinished];
    };
    
    void (^ __nullable actionCancel)(UIAlertAction *action) = ^(UIAlertAction *action) {
        self.state = usercancelled;
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
