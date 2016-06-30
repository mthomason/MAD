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
#import "MADErrorUserInfo.h"
#import <CoreFoundation/CFData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADThread.h>
#import <dispatch/dispatch.h>
#import <Security/SecItem.h>

NSString * const MTKeyChainUsernameAccountDesc = @"Client Database Username";
NSString * const MTKeyChainPasswordAccountDesc = @"Client Database Password";

const NSInteger MTKeyErrorUserCanceled = 393920;

@interface MTKeyChain()

    @property (nonatomic, strong) NSString *credentialsUsername;
    @property (nonatomic, strong) NSString *saveUsername;
    @property (nonatomic, strong) NSString *savePassword;

@end

@implementation MTKeyChain

static MTKeyChain *sharedSingleton = nil;

- (void)dealloc {
    NSAssert(NO, @"Don't dealloc the singleton.");
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        sharedSingleton.credentialsUsername = @"";
        sharedSingleton.savePassword = @"";
        sharedSingleton.saveUsername = @"";
    });
}

+ (MTKeyChain *)sharedObject {
    return sharedSingleton;
}

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

+ (NSString *)keyForUsernameWithMainKey:(NSString *)key {
    id result = [[NSString alloc] initWithFormat:@"u:%@", key];
    return result;
}

+ (NSString *)keyForPasswordWithMainKey:(NSString *)key {
    return [NSString stringWithFormat:@"p:%@", key];
}

+ (NSDictionary *)newDictionaryQueryGeneric:(NSString *)key {
    const NSNumber *yes = @YES;
    NSString *keyCopy = key.copy;
    NSDictionary *query = [[NSDictionary alloc] initWithObjectsAndKeys:
                            (__bridge id)kSecClassGenericPassword,  (__bridge id)(kSecClass),
                            keyCopy,                                (__bridge id)(kSecAttrService),
                            @"Generic",                             (__bridge id)(kSecAttrAccount),
                            yes,                                    (__bridge id)(kSecReturnData),
                            nil];
    return query;
}

+ (NSDictionary *)queryUsernameDefination:(NSString *)key {
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    const NSNumber *yes = @YES;
    NSDictionary *query = [[NSDictionary alloc] initWithObjectsAndKeys:
                            (__bridge id)kSecClassGenericPassword,  (__bridge id)(kSecClass),
                            keyUsername,                            (__bridge id)(kSecAttrService),
                            MTKeyChainUsernameAccountDesc,          (__bridge id)(kSecAttrAccount),
                            yes,                                    (__bridge id)(kSecReturnData),
                            nil];

    return query;
}

+ (NSDictionary *)queryPasswordDefination:(NSString *)key {
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    const NSNumber *yes = @YES;
    NSDictionary *query = [[NSDictionary alloc] initWithObjectsAndKeys:
                            (__bridge id)kSecClassGenericPassword,  (__bridge id)(kSecClass),
                            keyPassword,                            (__bridge id)(kSecAttrService),
                            MTKeyChainPasswordAccountDesc,          (__bridge id)(kSecAttrAccount),
                            yes,                                    (__bridge id)(kSecReturnData),
                            nil];
    return query;
}

+ (NSDictionary *)queryDefination:(NSString *)key withDescription:(NSString *)description {
    NSNumber *yes = @YES;
    NSString *keyCopy = key.copy;
    NSString *descriptionCopy = description.copy;
    NSDictionary *query = @{(__bridge id)(kSecClass) : (__bridge id)(kSecClassGenericPassword),
                            (__bridge id)(kSecAttrService) : keyCopy,
                            (__bridge id)(kSecAttrAccount) : descriptionCopy,
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

+ (NSDictionary *)queryAdd:(NSString *)token forKey:(NSString *)key withDescription:(NSString *)description {
    NSData *data = [token dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{(__bridge id)(kSecClass) : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)(kSecAttrService) : key,
                            (__bridge id)(kSecAttrAccount) : description, // MTKeyChainUsernameAccountDesc,
                            (__bridge id)(kSecValueData) : data};
    return query;
}

+ (NSDictionary *)queryUpdate:(NSString *)key withDescription:(NSString *)description {
    NSDictionary *query = @{(__bridge id)(kSecClass): (__bridge id)(kSecClassGenericPassword),
                            (__bridge id)(kSecAttrService): key,
                            (__bridge id)(kSecAttrAccount): description}; // MTKeyChainUsernameAccountDesc};
    return query;
}

+ (NSDictionary *)queryUsernameUpdate:(NSString *)key {
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSDictionary *query = @{(__bridge id)(kSecClass): (__bridge id)(kSecClassGenericPassword),
                            (__bridge id)(kSecAttrService): keyUsername,
                            (__bridge id)(kSecAttrAccount): MTKeyChainUsernameAccountDesc};
    return query;
}

+ (NSDictionary *)queryUpdateData:(NSString *)token {
    NSData *d = [token dataUsingEncoding: NSUTF8StringEncoding];
    NSDictionary *query = @{(__bridge id)(kSecValueData): d};
    return query;
}

+ (NSDictionary *)queryPasswordUpdateData:(NSString *)password {
    NSDictionary *result = [self queryUpdateData:password];
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
    NSString *domain = @"MTKeyChain";
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
    NSError *error = [errorUserInfo errorWithDomain:domain code:MTKeyErrorUserCanceled];
    return error;
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

+ (OSStatus)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key {
    
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    OSStatus status = [MTKeyChain saveToken:username forKey:keyUsername withDescription:MTKeyChainUsernameAccountDesc];
    
    if (status == errSecSuccess) {
        NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
        [MTKeyChain saveToken:password forKey:keyPassword withDescription:MTKeyChainPasswordAccountDesc];
    }
    return status;
}

+ (OSStatus)savePassword:(NSString *)password forKey:(NSString *)key  {
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
    return [MTKeyChain saveToken:password forKey:keyPassword withDescription:MTKeyChainPasswordAccountDesc];
}

+ (OSStatus)saveUsername:(NSString *)username forKey:(NSString *)key  {
    
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    return [MTKeyChain saveToken:username forKey:keyUsername withDescription:MTKeyChainUsernameAccountDesc];
}

+ (OSStatus)saveToken:(NSString *)token forKey:(NSString *)key withDescription:(NSString *)description {
    const NSNumber *yes = @YES;
    NSDictionary *queryUsername = @{(__bridge id)(kSecClass) : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)(kSecAttrService) : key,
                                    (__bridge id)(kSecAttrAccount) : description, // MTKeyChainUsernameAccountDesc,
                                    (__bridge id)(kSecReturnData) : yes};
    
    CFDataRef queryUsernameData = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
    
    
    if (status == errSecItemNotFound) {
        NSDictionary *queryAddUsername = [MTKeyChain queryAdd:token forKey:key withDescription:description];
        status = SecItemAdd((__bridge CFDictionaryRef)queryAddUsername, NULL);
    } else {
        NSDictionary *updateQueryUsername = [MTKeyChain queryUpdate:key withDescription:description];
        NSDictionary *changesUsername = [MTKeyChain queryUpdateData:token];
        status = SecItemUpdate((__bridge CFDictionaryRef)updateQueryUsername, (__bridge CFDictionaryRef)changesUsername);
    }
    return status;
}

+ (void)deleteKey:(NSString *)key {
    NSDictionary *query = [MTKeyChain newDictionaryQueryGeneric:key];
    
    CFDataRef queryData = NULL;
    
    OSStatus deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) query, (CFTypeRef *)&queryData);
    if (deleteStatus == errSecSuccess) {
        deleteStatus = SecItemDelete((__bridge CFDictionaryRef)query);
    }
}

+ (void)deleteSavedPasswordForKey:(NSString *)key {
    
    NSDictionary *queryUsername = [MTKeyChain queryUsernameDefination:key];
    NSDictionary *queryPassword = [MTKeyChain queryPasswordDefination:key];
    
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

@end
