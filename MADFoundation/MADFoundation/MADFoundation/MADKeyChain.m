//
//  MADKeyChain.m
//  Reports
//
//  Created by Michael Thomason on 8/5/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADKeyChain.h"

#import <dispatch/dispatch.h>
#import <Security/SecItem.h>

#import <CoreFoundation/CFData.h>

#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>

NSString * const MADKeyChainUsernameAccountDesc = @"Client Database Username";
NSString * const MADKeyChainPasswordAccountDesc = @"Client Database Password";

@implementation MADKeyChain

+ (NSString *)newKeyForUsernameWithMainKey:(NSString *)key {
	return [[NSString alloc] initWithFormat:@"u:%@", key];
}

+ (NSString *)newKeyForPasswordWithMainKey:(NSString *)key {
	return [[NSString alloc] initWithFormat:@"p:%@", key];
}

+ (NSDictionary *)newDictionaryQueryGeneric:(NSString *)key {
	NSNumber *yes = @YES;
	NSString *keyCopy = key.copy;
	NSDictionary *query;
	query = [[NSDictionary alloc] initWithObjectsAndKeys:
				(__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)(kSecClass),
				keyCopy, (__bridge NSString *)(kSecAttrService),
				@"Generic", (__bridge NSString *)(kSecAttrAccount),
				yes, (__bridge NSString *)(kSecReturnData), nil];
	return query;
}

+ (NSDictionary *)queryUsernameDefination:(NSString *)key {
	NSString *keyUsername = [MADKeyChain newKeyForUsernameWithMainKey: key];
	NSNumber *yes = @YES;
	NSDictionary *query;
	query = [[NSDictionary alloc] initWithObjectsAndKeys:
				(__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)(kSecClass),
				keyUsername, (__bridge NSString *)(kSecAttrService),
				MADKeyChainUsernameAccountDesc, (__bridge NSString *)(kSecAttrAccount),
				yes, (__bridge NSString *)(kSecReturnData), nil];
	return query;
}

+ (NSDictionary *)queryPasswordDefination:(NSString *)key {
	NSString *keyPassword = [MADKeyChain newKeyForPasswordWithMainKey: key];
	NSNumber *yes = @YES;
	NSDictionary *query;
	query = [[NSDictionary alloc] initWithObjectsAndKeys:
				(__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)(kSecClass),
				keyPassword, (__bridge NSString *)(kSecAttrService),
				MADKeyChainPasswordAccountDesc, (__bridge NSString *)(kSecAttrAccount),
				yes, (__bridge NSString *)(kSecReturnData), nil];
	return query;
}

+ (NSDictionary *)queryDefination:(NSString *)key withDescription:(NSString *)description {
	NSNumber *yes = @YES;
	NSString *keyCopy = key.copy;
	NSString *descriptionCopy = description.copy;
	NSDictionary *query;
	query = @{(__bridge NSString *)(kSecClass) : (__bridge NSString *)(kSecClassGenericPassword),
			  (__bridge NSString *)(kSecAttrService) : keyCopy,
			  (__bridge NSString *)(kSecAttrAccount) : descriptionCopy,
			  (__bridge NSString *)(kSecReturnData) : yes};
	return query;
}

+ (NSDictionary *)queryUsernameAdd:(NSString *)username key:(NSString *)key {
	NSString *keyUsername = [MADKeyChain newKeyForUsernameWithMainKey: key];
	NSData *data = [username dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *query;
	query = @{(__bridge NSString *)(kSecClass) : (__bridge NSString *)kSecClassGenericPassword,
			  (__bridge NSString *)(kSecAttrService) : keyUsername,
			  (__bridge NSString *)(kSecAttrAccount) : MADKeyChainUsernameAccountDesc,
			  (__bridge NSString *)(kSecValueData) : data};
	return query;
}

+ (NSDictionary *)queryAdd:(NSString *)token
					forKey:(NSString *)key
		   withDescription:(NSString *)description {
	NSData *data = [token dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *query;
	query = @{(__bridge NSString *)(kSecClass) : (__bridge NSString *)kSecClassGenericPassword,
			  (__bridge NSString *)(kSecAttrService) : key,
			  (__bridge NSString *)(kSecAttrAccount) : description,
			  (__bridge NSString *)(kSecValueData) : data};
	return query;
}

+ (NSDictionary *)queryUpdate:(NSString *)key withDescription:(NSString *)description {
	NSDictionary *query;
	query = @{(__bridge NSString *)(kSecClass): (__bridge NSString *)(kSecClassGenericPassword),
			  ((NSString *)kSecAttrService): key,
			  (__bridge NSString *)(kSecAttrAccount): description};
	return query;
}

+ (NSDictionary *)queryUsernameUpdate:(NSString *)key {
	NSString *keyUsername = [MADKeyChain newKeyForUsernameWithMainKey: key];
	NSDictionary *query;
	query = @{(__bridge NSString *)(kSecClass): (__bridge NSString *)(kSecClassGenericPassword),
			  (__bridge NSString *)(kSecAttrService): keyUsername,
			  (__bridge NSString *)(kSecAttrAccount): MADKeyChainUsernameAccountDesc};
	return query;
}

+ (NSDictionary *)queryUpdateData:(NSString *)token {
	NSData *d = [token dataUsingEncoding: NSUTF8StringEncoding];
	NSDictionary *query = @{(__bridge NSString *)(kSecValueData): d};
	return query;
}

+ (NSDictionary *)queryPasswordUpdateData:(NSString *)password {
	NSDictionary *result = [self queryUpdateData:password];
	return [NSDictionary dictionaryWithDictionary:result];
}

+ (NSDictionary *)queryPasswordAdd:(NSString *)password key:(NSString *)key {
	NSString *keyPassword = [MADKeyChain newKeyForPasswordWithMainKey: key];
	NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *query;
	query = @{(__bridge NSString *)(kSecClass) : (__bridge NSString *)kSecClassGenericPassword,
			  (__bridge NSString *)(kSecAttrService) : keyPassword,
			  (__bridge NSString *)(kSecAttrAccount) : MADKeyChainPasswordAccountDesc,
			  (__bridge NSString *)(kSecValueData) : data};
	return query;
}

+ (NSDictionary *)queryPasswordUpdate:(NSString *)key {
	NSString *keyPassword = [MADKeyChain newKeyForPasswordWithMainKey: key];
	NSDictionary *query;
	query = @{(__bridge NSString *)(kSecClass): (__bridge NSString *)(kSecClassGenericPassword),
			  (__bridge NSString *)(kSecAttrService): keyPassword,
			  (__bridge NSString *)(kSecAttrAccount): MADKeyChainPasswordAccountDesc};
	return query;
}

+ (BOOL)credentialsExist:(NSString *)key {
	CFDataRef queryUsernameData = NULL;
	NSDictionary *queryUsername = [MADKeyChain queryUsernameDefination:key];
	OSStatus queryUsernameStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername,
													   (CFTypeRef *)&queryUsernameData);
	return errSecItemNotFound != queryUsernameStatus;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

+ (OSStatus)saveUsername:(NSString *)username andPassword:(NSString *)password
				  forKey:(NSString *)key {
	
	NSString *keyUsername = [MADKeyChain newKeyForUsernameWithMainKey: key];
	OSStatus status = [MADKeyChain saveToken: username forKey: keyUsername
							 withDescription: MADKeyChainUsernameAccountDesc];
	
	if (status == errSecSuccess) {
		NSString *keyPassword = [MADKeyChain newKeyForPasswordWithMainKey: key];
		[MADKeyChain saveToken: password forKey: keyPassword
			   withDescription: MADKeyChainPasswordAccountDesc];
	}
	return status;
}

+ (OSStatus)savePassword:(NSString *)password forKey:(NSString *)key  {
	NSString *keyPassword = [MADKeyChain newKeyForPasswordWithMainKey: key];
	return [MADKeyChain saveToken: password forKey: keyPassword
				  withDescription: MADKeyChainPasswordAccountDesc];
}

+ (OSStatus)saveUsername:(NSString *)username forKey:(NSString *)key  {
	
	NSString *keyUsername = [MADKeyChain newKeyForUsernameWithMainKey: key];
	return [MADKeyChain saveToken: username forKey: keyUsername
				  withDescription: MADKeyChainUsernameAccountDesc];
}

+ (OSStatus)saveToken:(NSString *)token
			   forKey:(NSString *)key
	  withDescription:(NSString *)description {
	NSDictionary *query = @{
		(__bridge NSString *)(kSecClass) : (__bridge NSString *)kSecClassGenericPassword,
		(__bridge NSString *)(kSecAttrService) : key,
		(__bridge NSString *)(kSecAttrAccount) : description,
		(__bridge NSString *)(kSecReturnData) : @YES
	};

	CFDataRef queryUsernameData = NULL;
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, (CFTypeRef *)&queryUsernameData);
	
	if (status == errSecItemNotFound) {
		NSDictionary *queryAddUsername = [MADKeyChain queryAdd: token forKey: key withDescription: description];
		return SecItemAdd((__bridge CFDictionaryRef)queryAddUsername, NULL);
	} else {
		NSDictionary *updateQueryUsername = [MADKeyChain queryUpdate: key withDescription: description];
		NSDictionary *changesUsername = [MADKeyChain queryUpdateData:token];
		return SecItemUpdate((__bridge CFDictionaryRef)updateQueryUsername,
							   (__bridge CFDictionaryRef)changesUsername);
	}
}

+ (OSStatus)deleteKey:(NSString *)key {
	
	NSDictionary *query = [MADKeyChain newDictionaryQueryGeneric:key];
	CFDataRef queryData = NULL;
	OSStatus deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) query,
												(CFTypeRef *)&queryData);
	if (deleteStatus == errSecSuccess) {
		deleteStatus = SecItemDelete((__bridge CFDictionaryRef)query);
	}
	return deleteStatus;
}

+ (bool)deleteSavedPasswordForKey:(NSString *)key error:(NSError * __autoreleasing *)error {
	
	NSDictionary *queryUsername = [MADKeyChain queryUsernameDefination:key];
	NSDictionary *queryPassword = [MADKeyChain queryPasswordDefination:key];
	
	CFDataRef queryUsernameData = NULL, queryPasswordData = NULL;
	
	NSError *deleteError = nil;
	OSStatus deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryUsername, (CFTypeRef *)&queryUsernameData);
	if (deleteStatus == errSecSuccess) {
		deleteStatus = SecItemDelete((__bridge CFDictionaryRef)queryUsername);
		if (deleteStatus != errSecSuccess) {
			deleteError = [NSError errorWithDomain:@"MADKeyChain" code:deleteStatus userInfo:nil];
		}
	}
	
	deleteStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryPassword,
									   (CFTypeRef *)&queryPasswordData);
	if (deleteStatus == errSecSuccess) {
		deleteStatus = SecItemDelete((__bridge CFDictionaryRef)queryPassword);
		if (deleteStatus != errSecSuccess && deleteError == nil) {
			deleteError = [NSError errorWithDomain:@"MADKeyChain" code:deleteStatus userInfo:nil];
		}
	}
	bool success = true;
	if (deleteError != nil && *error != nil) {
		*error = deleteError;
		success = false;
	}
	return success;
}

@end
