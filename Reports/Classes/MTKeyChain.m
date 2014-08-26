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

typedef void (^MTKeyChainCredentialsCompletion)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain);
typedef void (^MTKeyChainSaveCompletion)(BOOL success, NSError *error, NSString *username, NSString *password);

NSString * const MTKeyChainUsernameAccountDesc = @"Client Database Username";
NSString * const MTKeyChainPasswordAccountDesc = @"Client Database Password";

@interface MTKeyChain()
    <UIAlertViewDelegate>

@property (copy) MTKeyChainCredentialsCompletion credentialsCompletion;
@property (nonatomic, strong) NSString *credentialsUsername;
@property (nonatomic, strong) NSString *credentialsKey;

@property (copy) MTKeyChainSaveCompletion saveCompletion;
@property (nonatomic, strong) NSString *saveUsername;
@property (nonatomic, strong) NSString *savePassword;
@property (nonatomic, strong) NSString *saveKey;

@property (nonatomic, strong) UIAlertView *firstAlertView;

@property (nonatomic, strong) UITextField *textFieldOne;
@property (nonatomic, strong) UITextField *textFieldTwo;

@end

@implementation MTKeyChain

static MTKeyChain *sharedSingleton = nil;

const NSUInteger tagAlertViewRemovePassword = 888;
const NSUInteger tagAlertViewSave           = 777;
const NSUInteger tagAlertViewAquire         = 666;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        [sharedSingleton setCredentialsUsername:@""];
        [sharedSingleton setCredentialsKey:@""];
        [sharedSingleton setSaveKey:@""];
        [sharedSingleton setSavePassword:@""];
        [sharedSingleton setSaveUsername:@""];
    });
}

+ (MTKeyChain *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (NSString *)keyForUsernameWithMainKey:(NSString *)key {
    return [NSString stringWithFormat:@"u:%@", key];
}
+ (NSString *)keyForPasswordWithMainKey:(NSString *)key {
    return [NSString stringWithFormat:@"p:%@", key];
}

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key shortCircuit:(BOOL)shortCircuit completion:(void(^)(BOOL success, NSError *error, NSString *username, NSString *password))completion {
    if (shortCircuit == NO) {
        [self setSaveCompletion:completion];
        [self setSaveUsername:username];
        [self setSavePassword:password];
        [self setSaveKey:key];
        
        NSString *keyUsername = [[NSString alloc] initWithString:[MTKeyChain keyForUsernameWithMainKey: key]];
        NSString *keyPassword = [[NSString alloc] initWithString:[MTKeyChain keyForPasswordWithMainKey: key]];
        if (keyUsername == nil || keyPassword == nil || ![username isEqualToString:keyUsername] || ![password isEqualToString:keyPassword]) {
            
            NSString *title = NSLocalizedString(@"Save Credentials", @"Save Credentials");
            NSString *message = NSLocalizedString(@"Would you like to save the credentials to your key chain?", @"Would you like to save the credentials to your key chain?");
            NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel");
            NSString *continueButtonTitle = NSLocalizedString(@"Continue", @"Continue");
            UIAlertView *alertViewSaveToKeyChain = [[UIAlertView alloc] initWithTitle:title
                                                                              message:message
                                                                             delegate:self
                                                                    cancelButtonTitle:cancelButtonTitle
                                                                    otherButtonTitles:continueButtonTitle, nil];
            [alertViewSaveToKeyChain setTag:tagAlertViewSave];
            [alertViewSaveToKeyChain show];
            [self setFirstAlertView:alertViewSaveToKeyChain];
        }
    } else {
        completion(YES, nil, username, password);
    }
    
}

- (void)deleteKey:(NSString *)key {
    [self setCredentialsKey:key];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Remove Saved Password"
                                                        message:@"Should we remove the password saved in your keychain?"
                                                       delegate:self
                                              cancelButtonTitle:@"Keep"
                                              otherButtonTitles:@"Remove", nil];
    
    [alertView setAlertViewStyle:UIAlertViewStyleDefault];
    [alertView setTag:tagAlertViewRemovePassword];
    [self setFirstAlertView:alertView];
    [alertView performSelector:@selector(show) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
}

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key {
    [self setCredentialsKey:key];
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSDictionary *queryUsername = @{(__bridge id)kSecClass : (__bridge id)(kSecClassGenericPassword),
                                    (__bridge id)kSecAttrService : keyUsername,
                                    (__bridge id)kSecAttrAccount : MTKeyChainUsernameAccountDesc,
                                    (__bridge id)kSecReturnData : @YES};
    CFDataRef queryUsernameData = NULL;
    OSStatus queryUsernameStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    if (queryUsernameStatus == errSecItemNotFound) {
        NSDictionary *queryAddUsername = @{(__bridge id)(kSecClass) : (__bridge id)(kSecClassGenericPassword),
                                        (__bridge id)(kSecAttrService) : keyUsername,
                                        (__bridge id)(kSecAttrAccount) : MTKeyChainUsernameAccountDesc,
                                        (__bridge id)(kSecValueData) : [username dataUsingEncoding:NSUTF8StringEncoding]};
        OSStatus queryAddStatus = SecItemAdd((__bridge CFDictionaryRef)queryAddUsername, NULL);
        if (queryAddStatus != errSecSuccess) {
            SecItemAdd((__bridge CFDictionaryRef)queryAddUsername, NULL);
        }
    } else {
        NSDictionary *updateQueryUsername = @{(__bridge id)(kSecClass): (__bridge id)(kSecClassGenericPassword),
                                              (__bridge id)(kSecAttrService): keyUsername,
                                              (__bridge id)(kSecAttrAccount): MTKeyChainUsernameAccountDesc};
        NSDictionary *changesUsername = @{(__bridge id)(kSecValueData): [password dataUsingEncoding: NSUTF8StringEncoding]};
        OSStatus statusUsernameUpdate = SecItemUpdate((__bridge CFDictionaryRef)updateQueryUsername, (__bridge CFDictionaryRef)changesUsername);
        if (statusUsernameUpdate != errSecSuccess) {
            SecItemUpdate((__bridge CFDictionaryRef)updateQueryUsername, (__bridge CFDictionaryRef)changesUsername);
        }
    }
    
    
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    NSDictionary *queryPassword = @{(__bridge id)(kSecClass) : (__bridge id)(kSecClassGenericPassword),
                                    (__bridge id)(kSecAttrService) : keyPassword,
                                    (__bridge id)(kSecAttrAccount) : MTKeyChainPasswordAccountDesc,
                                    (__bridge id)(kSecReturnData) : @YES};
    
    CFDataRef queryPasswordData = NULL;
    OSStatus queryPasswordStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
    if (queryPasswordStatus == errSecItemNotFound) {
        NSDictionary *queryAddPassword = @{(__bridge id)(kSecClass) : (__bridge id)(kSecClassGenericPassword),
                                           (__bridge id)(kSecAttrService) : keyPassword,
                                           (__bridge id)(kSecAttrAccount) : MTKeyChainPasswordAccountDesc,
                                           (__bridge id)(kSecValueData) : [password dataUsingEncoding:NSUTF8StringEncoding]};
        OSStatus queryAddStatus = SecItemAdd((__bridge CFDictionaryRef)queryAddPassword, NULL);
        if (queryAddStatus != errSecSuccess) {
            SecItemAdd((__bridge CFDictionaryRef)queryAddPassword, NULL);
        }
    } else {
        NSDictionary *updateQueryPassword = @{(__bridge id)(kSecClass): (__bridge id)(kSecClassGenericPassword),
                                              (__bridge id)(kSecAttrService): [MTKeyChain keyForPasswordWithMainKey: key],
                                              (__bridge id)(kSecAttrAccount): MTKeyChainPasswordAccountDesc};
        NSDictionary *changesPassword = @{(__bridge id)(kSecValueData): [password dataUsingEncoding: NSUTF8StringEncoding]};
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
    
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSDictionary *queryUsername = @{(__bridge id)(kSecClass) : (__bridge id)(kSecClassGenericPassword),
                                    (__bridge id)(kSecAttrService) : keyUsername,
                                    (__bridge id)(kSecAttrAccount) : MTKeyChainUsernameAccountDesc,
                                    (__bridge id)(kSecReturnData) : @YES};
    CFDataRef queryUsernameData = NULL;

    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    NSDictionary *queryPassword = @{(__bridge id)(kSecClass) : (__bridge id)(kSecClassGenericPassword),
                                    (__bridge id)(kSecAttrService) : keyPassword,
                                    (__bridge id)(kSecAttrAccount) : MTKeyChainPasswordAccountDesc,
                                    (__bridge id)(kSecReturnData) : @YES};
    
    CFDataRef queryPasswordData = NULL;
    
    //SecItemDelete((CFDictionaryRef)queryUsername);
    //SecItemDelete((CFDictionaryRef)queryPassword);
    
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
            NSString *username = nil;
            NSString *password = nil;
            username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData
                                              encoding:NSUTF8StringEncoding];
            password = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryPasswordData
                                              encoding:NSUTF8StringEncoding];
            completion(YES, nil, username, password, YES);
            break;
        }
        case stateGetPassword: {
            //Username found.  What about password?
            NSString *username = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryUsernameData
                                                        encoding:NSUTF8StringEncoding];
            SEL promptForPasswordGivenUsername = @selector(promptForPasswordGivenUsername:);
            [self performSelectorOnMainThread:promptForPasswordGivenUsername withObject:username waitUntilDone:NO];
            break;
        }
        case stateGetUsernameAndPassword: {
            SEL promptForUsernameAndPassword = @selector(promptForUsernameAndPassword);
            [self performSelectorOnMainThread:promptForUsernameAndPassword withObject:nil waitUntilDone:NO];
            break;
        }
        default:
            completion(NO, nil, nil, nil, NO);
            break;
    }
}

- (void)promptForPasswordGivenUsername:(NSString *)username {
    [self setCredentialsUsername:username];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password"
                                                        message:@"Please enter your password."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Continue", nil];
    [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [alertView setTag:tagAlertViewAquire];
    alertView.delegate = self;
    [self setTextFieldOne:[alertView textFieldAtIndex:0]];
    [self setTextFieldTwo:[alertView textFieldAtIndex:1]];
    [alertView show];
    [self setFirstAlertView:alertView];
}

- (void)promptForUsernameAndPassword {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Credentials"
                                                        message:@"Please enter your credentials."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Continue", nil];
    [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    alertView.delegate = self;
    [alertView setTag:tagAlertViewAquire];
    [self setTextFieldOne:[alertView textFieldAtIndex:0]];
    [self setTextFieldTwo:[alertView textFieldAtIndex:1]];
    [alertView show];
    [self setFirstAlertView:alertView];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    BOOL success = NO;
    BOOL canceled = [alertView cancelButtonIndex] == buttonIndex;
    switch ([alertView tag]) {
            
        case tagAlertViewAquire: {
            NSString *username = nil;
            NSString *password = nil;
            if (canceled == NO) {
                switch ([alertView alertViewStyle]) {
                    case UIAlertViewStyleSecureTextInput:
                        success = YES;
                        username = [self credentialsUsername];
                        password = [[alertView textFieldAtIndex:0] text];
                        break;
                    case UIAlertViewStyleLoginAndPasswordInput:
                        success = YES;
                        username = [[alertView textFieldAtIndex:0] text];
                        password = [[alertView textFieldAtIndex:1] text];
                        if (username == nil) {
                            username = @"";
                        }
                        if (password == nil) {
                            password = @"";
                        }
                        break;
                    default:
                        break;
                }
            }
            
            [self credentialsCompletion](success, nil, username, password, NO);
            break;
        }
            
        case tagAlertViewSave: {
            if (canceled == NO) {
                [self saveUsername:[self saveUsername]
                       andPassword:[self savePassword]
                            forKey:[self saveKey]];
            }
            NSString *u = [[NSString alloc] initWithString:[self saveUsername]];
            NSString *p = [[NSString alloc] initWithString:[self savePassword]];
            [self saveCompletion](!canceled, nil, u, p);
            break;
        }
            
        case tagAlertViewRemovePassword: {
            
            if (canceled == NO) {
            
                NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: [self credentialsKey]];
                NSDictionary *queryUsername = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                                (__bridge id)kSecAttrService : keyUsername,
                                                (__bridge id)kSecAttrAccount : MTKeyChainUsernameAccountDesc,
                                                (__bridge id)kSecReturnData : @YES};
                CFDataRef queryUsernameData = NULL;
                OSStatus deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
                if (deleteStatus == errSecSuccess) {
                    
                    deleteStatus = SecItemDelete((__bridge CFDictionaryRef)queryUsername);
                    
                    
                }
                
                CFDataRef queryPasswordData = NULL;
                NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: [self credentialsKey]];
                NSDictionary *queryPassword = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                                (__bridge id)kSecAttrService : keyPassword,
                                                (__bridge id)kSecAttrAccount : MTKeyChainPasswordAccountDesc,
                                                (__bridge id)kSecReturnData : @YES};
                deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
                
                if (deleteStatus == errSecSuccess) {
                    deleteStatus = SecItemDelete((__bridge CFDictionaryRef)queryPassword);
                }
            }
            break;
        }
            
        default:
            break;
    }
    [self setTextFieldOne:nil];
    [self setTextFieldTwo:nil];

}

- (void)alertViewCancel:(UIAlertView *)alertView {
    switch ([alertView tag]) {
        case tagAlertViewAquire: {
            [self credentialsCompletion](NO, nil, nil, nil, NO);
            break;
        }
        case tagAlertViewSave: {
            [self saveCompletion](NO, nil, nil, nil);
            break;
        }
            default:
            break;
    }
}

@end
