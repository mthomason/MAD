//
//  MTKeyChain.m
//  Reports
//
//  Created by Michael Thomason on 8/5/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTKeyChain.h"

typedef void (^MTKeyChainCredentialsCompletion)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain);
typedef void (^MTKeyChainSaveCompletion)(BOOL success, NSError *error, NSString *username, NSString *password);

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

@property (nonatomic, retain) UITextField *textFieldOne;
@property (nonatomic, retain) UITextField *textFieldTwo;

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
    //Leaks because of singleton... fine.
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

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key shortCircuit:(BOOL)shortCircuit completion:(void(^)(BOOL success, NSError *error, NSString *username, NSString *password))completion {
    if (shortCircuit == NO) {
        [self setSaveCompletion:completion];
        [self setSaveUsername:username];
        [self setSavePassword:password];
        [self setSaveKey:key];
        
        NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
        NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
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
            [alertViewSaveToKeyChain release];
        }
    } else {
        completion(YES, nil, [[username retain] autorelease], [[password retain] autorelease]);
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
    if ([NSThread isMainThread]) {
        [alertView show];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [alertView show];
        });
    }
    [alertView release];
}

- (void)askShouldWeKeep {
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSString *username = [[[NSString alloc] initWithData:queryUsernameData
                                                                encoding:NSUTF8StringEncoding] autorelease];
                    [self setCredentialsUsername:username];
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password"
                                                                        message:@"Please enter your password."
                                                                       delegate:self
                                                              cancelButtonTitle:@"Cancel"
                                                              otherButtonTitles:@"Continue", nil];
                    [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
                    [alertView setTag:tagAlertViewAquire];
                    [alertView setDelegate:self];
                    [self setTextFieldOne:[alertView textFieldAtIndex:0]];
                    [self setTextFieldTwo:[alertView textFieldAtIndex:1]];
                    [alertView show];
                    [self setFirstAlertView:alertView];
                    [alertView release];

                
                });
            });
            break;
        }
        case stateGetUsernameAndPassword: {
            //Username found.  What about password?
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Credentials"
                                                                        message:@"Please enter your credentials."
                                                                       delegate:self
                                                              cancelButtonTitle:@"Cancel"
                                                              otherButtonTitles:@"Continue", nil];
                    [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
                    [alertView setDelegate:self];
                    [alertView setTag:tagAlertViewAquire];
                    [self setTextFieldOne:[alertView textFieldAtIndex:0]];
                    [self setTextFieldTwo:[alertView textFieldAtIndex:1]];
                    [alertView show];
                    [self setFirstAlertView:alertView];
                    [alertView release];
                });
            });
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

+ (NSString *)keyForServer:(NSString *)server port:(NSInteger)port andDatabase:(NSString *)database {
    return [[[NSString stringWithFormat:@"[%@:%ld]%@", server,  (long)port, database] retain] autorelease];
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
                [self saveUsername:[self saveUsername] andPassword:[self savePassword] forKey:[self saveKey]];
            }
            NSString *u = [[self saveUsername] retain];
            NSString *p = [[self savePassword] retain];
            [self saveCompletion](!canceled, nil, u, p);
            [u release];
            [p release];
            break;
        }
            
        case tagAlertViewRemovePassword: {
            
            if (canceled == NO) {
            
                NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: [self credentialsKey]];
                NSDictionary *queryUsername = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                                (id)kSecAttrService : keyUsername,
                                                (id)kSecAttrAccount : MTKeyChainUsernameAccountDesc,
                                                (id)kSecReturnData : @YES};
                NSData *queryUsernameData = NULL;
                OSStatus deleteStatus = SecItemCopyMatching((CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
                if (deleteStatus == errSecSuccess) {
                    
                    deleteStatus = SecItemDelete((CFDictionaryRef)queryUsername);
                    
                    
                }
                
                NSData *queryPasswordData = NULL;
                NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: [self credentialsKey]];
                NSDictionary *queryPassword = @{(id)kSecClass : (id)kSecClassGenericPassword,
                                                (id)kSecAttrService : keyPassword,
                                                (id)kSecAttrAccount : MTKeyChainPasswordAccountDesc,
                                                (id)kSecReturnData : @YES};
                deleteStatus = SecItemCopyMatching((CFDictionaryRef) queryPassword, (CFTypeRef *)&queryPasswordData);
                
                if (deleteStatus == errSecSuccess) {
                    deleteStatus = SecItemDelete((CFDictionaryRef)queryPassword);
                }
            }
//            return deleteStatus;
            
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
