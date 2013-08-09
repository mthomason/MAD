//
//  MTKeyChain.m
//  Reports
//
//  Created by Michael Thomason on 8/5/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTKeyChain.h"

typedef void (^MTKeyChainCredentialsCompletion)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain);
typedef void (^MTKeyChainSaveCompletion)(BOOL success, NSError *error);

NSString * const MTKeyChainUsernameAccountDesc = @"Client Database Username";
NSString * const MTKeyChainPasswordAccountDesc = @"Client Database Password";

@interface MTKeyChain()
    <UIAlertViewDelegate>

@property (copy) MTKeyChainCredentialsCompletion credentialsCompletion;
@property (nonatomic, retain) NSString *credentialsUsername;
@property (nonatomic, retain) NSString *credentialsKey;

@property (copy) MTKeyChainSaveCompletion saveCompletion;
@property (nonatomic, retain) NSString *saveUsername;
@property (nonatomic, retain) NSString *savePassword;
@property (nonatomic, retain) NSString *saveKey;

@property (nonatomic, retain) UIAlertView *firstAlertView;

@end

@implementation MTKeyChain

static MTKeyChain *sharedSingleton = nil;
const NSUInteger tagAlertViewSave = 777;
const NSUInteger tagAlertViewAquire = 666;

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
    return [[self sharedObject] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release {
    
}

- (id)autorelease {
    return self;
}

+ (NSString *)keyForUsernameWithMainKey:(NSString *)key {
    return [NSString stringWithFormat:@"u:%@", key];
}
+ (NSString *)keyForPasswordWithMainKey:(NSString *)key {
    return [NSString stringWithFormat:@"p:%@", key];
}

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key completion:(void(^)(BOOL success, NSError *error))completion {
    [self setSaveCompletion:completion];
    [self setSaveUsername:username];
    [self setSavePassword:password];
    [self setSaveKey:key];
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
    [alertViewSaveToKeyChain release];
    
}

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key {
    [self setCredentialsKey:key];
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSDictionary *queryUsername = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                    (id)kSecAttrService : keyUsername,
                                    (id)kSecAttrAccount : MTKeyChainUsernameAccountDesc,
                                    (id)kSecReturnData : @YES};
    NSData *queryUsernameData = NULL;
    OSStatus queryUsernameStatus = SecItemCopyMatching((CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    if (queryUsernameStatus == errSecItemNotFound) {
        NSDictionary *queryAddUsername = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                        (id)kSecAttrService : keyUsername,
                                        (id)kSecAttrAccount : MTKeyChainUsernameAccountDesc,
                                        (id)kSecValueData : [username dataUsingEncoding:NSUTF8StringEncoding]};
        OSStatus queryAddStatus = SecItemAdd((CFDictionaryRef)queryAddUsername, NULL);
        if (queryAddStatus != errSecSuccess) {
            SecItemAdd((CFDictionaryRef)queryAddUsername, NULL);
        }
    } else {
        NSDictionary *updateQueryUsername = @{(id)kSecClass: (id)kSecClassGenericPassword,
                                              (id)kSecAttrService: keyUsername,
                                              (id)kSecAttrAccount: MTKeyChainUsernameAccountDesc};
        NSDictionary *changesUsername = @{(id)kSecValueData: [password dataUsingEncoding: NSUTF8StringEncoding]};
        OSStatus statusUsernameUpdate = SecItemUpdate((CFDictionaryRef)updateQueryUsername, (CFDictionaryRef)changesUsername);
        if (statusUsernameUpdate != errSecSuccess) {
            SecItemUpdate((CFDictionaryRef)updateQueryUsername, (CFDictionaryRef)changesUsername);
        }
    }
    
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    NSDictionary *queryPassword = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                    (id)kSecAttrService : keyPassword,
                                    (id)kSecAttrAccount : MTKeyChainPasswordAccountDesc,
                                    (id)kSecReturnData : @YES};
    
    NSData *queryPasswordData = NULL;
    OSStatus queryPasswordStatus = SecItemCopyMatching((CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
    if (queryPasswordStatus == errSecItemNotFound) {
        NSDictionary *queryAddPassword = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                           (id)kSecAttrService : keyPassword,
                                           (id)kSecAttrAccount : MTKeyChainPasswordAccountDesc,
                                           (id)kSecValueData : [password dataUsingEncoding:NSUTF8StringEncoding]};
        OSStatus queryAddStatus = SecItemAdd((CFDictionaryRef)queryAddPassword, NULL);
        if (queryAddStatus != errSecSuccess) {
            SecItemAdd((CFDictionaryRef)queryAddPassword, NULL);
        }
    } else {
        NSDictionary *updateQueryPassword = @{(id)kSecClass: (id)kSecClassGenericPassword,
                                              (id)kSecAttrService: [MTKeyChain keyForPasswordWithMainKey: key],
                                              (id)kSecAttrAccount: MTKeyChainPasswordAccountDesc};
        NSDictionary *changesPassword = @{(id)kSecValueData: [password dataUsingEncoding: NSUTF8StringEncoding]};
        OSStatus statusPasswordUpdate = SecItemUpdate((CFDictionaryRef)updateQueryPassword, (CFDictionaryRef)changesPassword);
        if (statusPasswordUpdate != errSecSuccess) {
            SecItemUpdate((CFDictionaryRef)updateQueryPassword, (CFDictionaryRef)changesPassword);
        }
    }
}

- (void)getUsernameAndPasswordForKey:(NSString *)key completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain))completion {
    [self setCredentialsCompletion:completion];
    
    const NSInteger stateGetPassword = 1;
    const NSInteger stateGetUsernameAndPassword = 2;
    const NSInteger stateGetNothing = 3;
    NSInteger status;
    
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSDictionary *queryUsername = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                    (id)kSecAttrService : keyUsername,
                                    (id)kSecAttrAccount : MTKeyChainUsernameAccountDesc,
                                    (id)kSecReturnData : @YES};
    NSData *queryUsernameData = NULL;

    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    NSDictionary *queryPassword = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                    (id)kSecAttrService : keyPassword,
                                    (id)kSecAttrAccount : MTKeyChainPasswordAccountDesc,
                                    (id)kSecReturnData : @YES};
    
    NSData *queryPasswordData = NULL;
    
    //SecItemDelete((CFDictionaryRef)queryUsername);
    //SecItemDelete((CFDictionaryRef)queryPassword);
    
    OSStatus queryUsernameStatus = SecItemCopyMatching((CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    OSStatus queryPasswordStatus = SecItemCopyMatching((CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
    
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
            username = [[[NSString alloc] initWithData:queryUsernameData
                                              encoding:NSUTF8StringEncoding] autorelease];
            password = [[[NSString alloc] initWithData:queryPasswordData
                                              encoding:NSUTF8StringEncoding] autorelease];
            completion(YES, nil, username, password, YES);
            break;
        }
        case stateGetPassword: {
            //Username found.  What about password?
            //dispatch_async(dispatch_get_main_queue(), ^{
                NSString *username = [[[NSString alloc] initWithData:queryUsernameData
                                                            encoding:NSUTF8StringEncoding] autorelease];
                [self setCredentialsUsername:username];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password"
                                                                    message:@"Please enter your password."
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"Continue", nil];
                [alertView setAlertViewStyle:UIAlertViewStyleSecureTextInput];
                [alertView setTag:tagAlertViewAquire];
                [alertView show];
                [alertView release];
            //});
            break;
        }
        case stateGetUsernameAndPassword: {
            //Username found.  What about password?
            //dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Credentials"
                                                                    message:@"Please enter your credentials."
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"Continue", nil];
                [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
                [alertView setTag:tagAlertViewAquire];
                [alertView show];
                [alertView release];
            //});
            break;
        }
        default:
            completion(NO, nil, nil, nil, NO);
            break;
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    BOOL success = NO;
    switch ([alertView tag]) {
        case tagAlertViewAquire: {
            NSString *username = nil;
            NSString *password = nil;
            if ([alertView cancelButtonIndex] != buttonIndex) {
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
            BOOL canceled = [alertView cancelButtonIndex] == buttonIndex;
            if (!canceled) {
                [self saveUsername:[self saveUsername] andPassword:[self savePassword] forKey:[self saveKey]];
            }
            [self saveCompletion](!canceled, nil);
            break;
        }
        default:
            break;
    }
    
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    switch ([alertView tag]) {
        case tagAlertViewAquire: {
            [self credentialsCompletion](NO, nil, nil, nil, NO);
            break;
        }
        case tagAlertViewSave: {
            [self saveCompletion](NO, nil);
            break;
        }
            default:
            break;
    }
}

@end
