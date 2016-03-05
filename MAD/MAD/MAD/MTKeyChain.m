//
//  MTKeyChain.m
//  Reports
//
//  Created by Michael Thomason on 8/5/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTKeyChain.h"
#import <MADCocoaExtensions/MADError.h>
#import <MADCocoaExtensions/UIAlertController+Constructors.h>
#import <MADCocoaExtensions/NSThread+Extras.h>
#import <MADCocoaExtensions/MADStackViewController.h>

typedef void (^MTKeyChainCredentialsCompletion)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain);
typedef void (^MTKeyChainSaveCompletion)(BOOL success, NSError *error, NSString *username, NSString *password);

NSString * const MTKeyChainUsernameAccountDesc = @"Client Database Username";
NSString * const MTKeyChainPasswordAccountDesc = @"Client Database Password";

NSInteger const MTKeyErrorUserCanceled = 393920;

@interface MTKeyChain()
    <UITextFieldDelegate>

@property (atomic, copy) MTKeyChainCredentialsCompletion credentialsCompletion;
@property (nonatomic, strong) NSString *credentialsUsername;
@property (nonatomic, strong) NSString *credentialsKey;

@property (atomic, copy) MTKeyChainSaveCompletion saveCompletion;
@property (nonatomic, strong) NSString *saveUsername;
@property (nonatomic, strong) NSString *savePassword;
@property (nonatomic, strong) NSString *saveKey;

@property (nonatomic, strong) UITextField *textFieldOne;
@property (nonatomic, strong) UITextField *textFieldTwo;

@end

@implementation MTKeyChain

static MTKeyChain *sharedSingleton = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        sharedSingleton.credentialsUsername = @"";
        sharedSingleton.credentialsKey = @"";
        sharedSingleton.saveKey = @"";
        sharedSingleton.savePassword = @"";
        sharedSingleton.saveUsername = @"";
    });
}

+ (MTKeyChain *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

+ (NSString *)keyForUsernameWithMainKey:(NSString *)key {
    return [NSString stringWithFormat:@"u:%@", key];
}

+ (NSString *)keyForPasswordWithMainKey:(NSString *)key {
    return [NSString stringWithFormat:@"p:%@", key];
}

+ (NSDictionary *)queryUsernameDefination:(NSString *)key {
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    const NSNumber *yes = @YES;
    NSDictionary *query = @{(__bridge id)(kSecClass) : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)(kSecAttrService) : keyUsername,
                            (__bridge id)(kSecAttrAccount) : MTKeyChainUsernameAccountDesc,
                            (__bridge id)(kSecReturnData) : yes};
    return query;
}

+ (NSDictionary *)queryPasswordDefination:(NSString *)key {
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    const NSNumber *yes = @YES;
    NSDictionary *query = @{(__bridge id)(kSecClass) : (__bridge id)(kSecClassGenericPassword),
                            (__bridge id)(kSecAttrService) : keyPassword,
                            (__bridge id)(kSecAttrAccount) : MTKeyChainPasswordAccountDesc,
                            (__bridge id)(kSecReturnData) : yes};
    return query;
}

+ (NSDictionary *)queryUsernameAdd:(NSString *)username key:(NSString *)key {
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSData *data = [username dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{(__bridge id)(kSecClass) : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)(kSecAttrService) : keyUsername,
                            (__bridge id)(kSecAttrAccount) : MTKeyChainUsernameAccountDesc,
                            (__bridge id)(kSecValueData) : data};
    return query;
}

+ (NSDictionary *)queryUsernameUpdate:(NSString *)key {
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSDictionary *query = @{(__bridge id)(kSecClass): (__bridge id)(kSecClassGenericPassword),
                            (__bridge id)(kSecAttrService): keyUsername,
                            (__bridge id)(kSecAttrAccount): MTKeyChainUsernameAccountDesc};
    return query;
}

+ (NSDictionary *)queryUsernameUpdateData:(NSString *)username {
    NSDictionary *query = @{(__bridge id)(kSecValueData): [username dataUsingEncoding: NSUTF8StringEncoding]};
    return query;
}

+ (NSDictionary *)queryPasswordUpdateData:(NSString *)password {
    NSDictionary *result = [self queryUsernameUpdateData:password];
    return [NSDictionary dictionaryWithDictionary:result];
}

+ (NSDictionary *)queryPasswordAdd:(NSString *)password key:(NSString *)key {
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{(__bridge id)(kSecClass) : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)(kSecAttrService) : keyPassword,
                            (__bridge id)(kSecAttrAccount) : MTKeyChainPasswordAccountDesc,
                            (__bridge id)(kSecValueData) : data};
    return query;
}

+ (NSDictionary *)queryPasswordUpdate:(NSString *)key {
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    NSDictionary *query = @{(__bridge id)(kSecClass): (__bridge id)(kSecClassGenericPassword),
                            (__bridge id)(kSecAttrService): keyPassword,
                            (__bridge id)(kSecAttrAccount): MTKeyChainPasswordAccountDesc};
    return query;
}

+ (NSError *)errorUserCanceled {
    NSString *title = NSLocalizedString(@"User Canceled", @"User Cancled");
    NSString *message = NSLocalizedString(@"User canceled save.", @"User canceled save.");
    return [MADError errorWithDomain: @"MTKeyChain" code: MTKeyErrorUserCanceled title: title andMessage: message];
}

+ (BOOL)credentialsExist:(NSString *)key {
    CFDataRef queryUsernameData = NULL;
    NSDictionary *queryUsername = [MTKeyChain queryUsernameDefination:key];
    OSStatus queryUsernameStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    return errSecItemNotFound != queryUsernameStatus;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)saveUsername:(NSString *)username
         andPassword:(NSString *)password
              forKey:(NSString *)key
        shortCircuit:(BOOL)shortCircuit completion:(void(^)(BOOL success, NSError *error, NSString *username, NSString *password))completion {
    
    if (shortCircuit == NO) {
        
        self.saveCompletion = completion;
        self.saveUsername = username;
        self.savePassword = password;
        self.saveKey = key;
        
        NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
        NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
        if (keyUsername == nil || keyPassword == nil || ![username isEqualToString:keyUsername] || ![password isEqualToString:keyPassword]) {
            
            UIAlertController *alertController = [MADAlertController saveCredentials:^(UIAlertAction *action) {
                
                [self saveUsername: self.saveUsername andPassword: self.savePassword forKey: self.saveKey];
                self.saveCompletion(YES, nil, self.saveUsername, self.savePassword);
                
            } cancel:^(UIAlertAction *action) {
                self.saveCompletion(NO, nil, nil, nil);
            }];

          [MADThread safeSwitchToMainThread:^{
                UIViewController *topViewController = [MADStackViewController topViewController];
                topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                [topViewController  presentViewController: alertController animated: YES completion: nil];
            }];
        }
        
    } else {
        completion(YES, nil, username, password);
    }
    
}

- (void)deleteKey:(NSString *)key usingViewController:(UIViewController *)viewController {
    if ([MTKeyChain credentialsExist:key]) {
        self.credentialsKey = key;
        
        UIAlertController *alertController = [MADAlertController removeCredentials:^(UIAlertAction *action) {
            [self deleteSavedPassword];
        } cancel:nil];
        
        [MADThread safeSwitchToMainThread:^{
            UIViewController *topViewController = viewController == nil ? [MADStackViewController topViewController] : viewController;
            topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [topViewController  presentViewController: alertController
                                             animated: YES
                                           completion: nil];
        }];
    } else {
        [self deleteSavedPassword];
    }
}

- (void)deleteKey:(NSString *)key {
    [self deleteKey:key usingViewController:nil];
}

- (void)deleteSavedPassword {
    
    NSDictionary *queryUsername = [MTKeyChain queryUsernameDefination:self.credentialsKey];
    NSDictionary *queryPassword = [MTKeyChain queryPasswordDefination:self.credentialsKey];
    CFDataRef queryUsernameData = NULL, queryPasswordData = NULL;
    
    OSStatus deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    if (deleteStatus == errSecSuccess) {
        deleteStatus = SecItemDelete((__bridge CFDictionaryRef)queryUsername);
    }
    
    deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
    if (deleteStatus == errSecSuccess) {
        deleteStatus = SecItemDelete((__bridge CFDictionaryRef)queryPassword);
    }

}

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key {
    self.credentialsKey = key;

    NSDictionary *queryUsername = [MTKeyChain queryUsernameDefination:self.credentialsKey];
    CFDataRef queryUsernameData = NULL, queryPasswordData = NULL;
    
    OSStatus queryUsernameStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    if (queryUsernameStatus == errSecItemNotFound) {
        NSDictionary *queryAddUsername = [MTKeyChain queryUsernameAdd:username key:key];
        OSStatus queryAddStatus = SecItemAdd((__bridge CFDictionaryRef)queryAddUsername, NULL);
        if (queryAddStatus != errSecSuccess) {
            SecItemAdd((__bridge CFDictionaryRef)queryAddUsername, NULL);
        }
    } else {
        NSDictionary *updateQueryUsername = [MTKeyChain queryUsernameUpdate:key];
        NSDictionary *changesUsername = [MTKeyChain queryUsernameUpdateData:username];
        OSStatus statusUsernameUpdate = SecItemUpdate((__bridge CFDictionaryRef)updateQueryUsername, (__bridge CFDictionaryRef)changesUsername);
        if (statusUsernameUpdate != errSecSuccess) {
            SecItemUpdate((__bridge CFDictionaryRef)updateQueryUsername, (__bridge CFDictionaryRef)changesUsername);
        }
    }
    
    
    NSDictionary *queryPassword = [MTKeyChain queryPasswordDefination:key];
    OSStatus queryPasswordStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
    if (queryPasswordStatus == errSecItemNotFound) {
        NSDictionary *queryAddPassword = [MTKeyChain queryPasswordAdd:password key:key];
        OSStatus queryAddStatus = SecItemAdd((__bridge CFDictionaryRef)queryAddPassword, NULL);
        if (queryAddStatus != errSecSuccess) {
            

            SecItemAdd((__bridge CFDictionaryRef)queryAddPassword, NULL);
        }
    } else {
        NSDictionary *updateQueryPassword = [MTKeyChain queryPasswordUpdate:key];
        NSDictionary *changesPassword = [MTKeyChain queryPasswordUpdateData:password];
        OSStatus statusPasswordUpdate = SecItemUpdate((__bridge CFDictionaryRef)updateQueryPassword, (__bridge CFDictionaryRef)changesPassword);
        if (statusPasswordUpdate != errSecSuccess) {
            SecItemUpdate((__bridge CFDictionaryRef)updateQueryPassword, (__bridge CFDictionaryRef)changesPassword);
        }
    }
}

- (void)getUsernameAndPasswordForKey:(NSString *)key
                          completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain))completion {
    
    [self setCredentialsCompletion:completion];
    
    const NSInteger stateGetPassword = 1;
    const NSInteger stateGetUsernameAndPassword = 2;
    const NSInteger stateGetNothing = 3;
    
    NSInteger status;
    CFDataRef queryUsernameData = NULL, queryPasswordData = NULL;
    NSDictionary *queryUsername = [MTKeyChain queryUsernameDefination:key];
    NSDictionary *queryPassword = [MTKeyChain queryPasswordDefination:key];
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
            //Items found.  Check for errors, then return.
            NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData encoding: NSUTF8StringEncoding];;
            NSString *password = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryPasswordData encoding: NSUTF8StringEncoding];
            completion(YES, nil, username, password, YES);
            break;
        }
        case stateGetPassword: {
            //Username found.  What about password?
            NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData
                                                        encoding:NSUTF8StringEncoding];
            SEL promptForPasswordGivenUsername = @selector(promptForPasswordGivenUsername:);
            [self performSelectorOnMainThread: promptForPasswordGivenUsername withObject: username waitUntilDone: NO];
            break;
        }
        case stateGetUsernameAndPassword: {
            SEL promptForUsernameAndPassword = @selector(promptForUsernameAndPassword);
            [self performSelectorOnMainThread: promptForUsernameAndPassword withObject: nil waitUntilDone: NO];
            break;
        }
        default:
            completion(NO, nil, nil, nil, NO);
            break;
    }
}

- (void)promptForPasswordGivenUsername:(NSString *)username {
    
    self.credentialsUsername = username;
    
    UIAlertController *prompt = [MADAlertController promptForPasswordGivenUsername:username password:^(UITextField *textField) {
        textField.delegate = self;
    } submit:^(NSString *password) {
        self.credentialsCompletion(YES, nil, username, password, NO);
    } cancel:^() {
        self.credentialsCompletion(NO, nil, nil, nil, NO);
    }];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = [MADStackViewController topViewController];
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: prompt animated: YES completion: nil];
    }];
    
}

- (void)promptForUsernameAndPassword {
    
    UIAlertController *prompt = [MADAlertController promptForUsername:^(UITextField *textField) {
        textField.delegate = self;
    } password:^(UITextField *textField) {
        textField.delegate = self;
    } submit:^(NSString *username, NSString *password) {
        self.credentialsCompletion(YES, nil, username, password, NO);
    } cancel:^() {
        NSError *error = [MTKeyChain errorUserCanceled];
        self.credentialsCompletion(NO, error, nil, nil, NO);
    }];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = [MADStackViewController topViewController];
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: prompt animated: YES completion: nil];
    }];
    
}

- (void)configureTextFieldForPassword:(UITextField **)textField {
    (*textField).delegate = self;
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

- (void)configureTextFieldForUsername:(UITextField **)textField {
    (*textField).delegate = self;
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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor darkGrayColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ((UILabel *)textField.leftView).textColor = [UIColor lightGrayColor];
}

@end
