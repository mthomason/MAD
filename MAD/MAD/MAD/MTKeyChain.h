//
//  MTKeyChain.h
//  Reports
//
//  Created by Michael Thomason on 8/5/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTKeyChain_h
#define MAD_MTKeyChain_h

#import <Foundation/NSObject.h>

extern NSInteger const MTKeyErrorUserCanceled;

@class UIViewController;

@interface MTKeyChain : NSObject

+ (MTKeyChain *)sharedObject;

+ (NSString *)keyForUsernameWithMainKey:(NSString *)key;
+ (NSString *)keyForPasswordWithMainKey:(NSString *)key;
+ (NSDictionary *)queryDefination:(NSString *)key;
+ (NSDictionary *)queryUsernameDefination:(NSString *)key;
+ (NSDictionary *)queryPasswordDefination:(NSString *)key;
+ (OSStatus)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key;

+ (OSStatus)savePassword:(NSString *)password forKey:(NSString *)key;
+ (OSStatus)saveUsername:(NSString *)username forKey:(NSString *)key;

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key
        shortCircuit:(BOOL)shortCircuit completion:(void(^)(BOOL success, NSError *error, NSString *username, NSString *password))completion;

- (void)getUsernameAndPasswordForKey:(NSString *)key completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain))completion;

// FIXME: Remove UIKit dependency.
- (void)deleteKey:(NSString *)key usingViewController:(UIViewController *)viewController;
- (void)deleteKey:(NSString *)key;

@end

#endif
