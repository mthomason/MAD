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

extern const NSInteger MTKeyErrorUserCanceled;
extern NSString * const MTKeyChainUsernameAccountDesc;
extern NSString * const MTKeyChainPasswordAccountDesc;

@class UIViewController;

@interface MTKeyChain : NSObject

    + (MTKeyChain *)sharedObject;

    + (OSStatus)saveToken:(NSString *)token forKey:(NSString *)key
          withDescription:(NSString *)description;
    + (NSDictionary *)queryDefination:(NSString *)key withDescription:(NSString *)description;

    + (NSString *)keyForUsernameWithMainKey:(NSString *)key;
    + (NSString *)keyForPasswordWithMainKey:(NSString *)key;
    + (NSDictionary *)queryUsernameDefination:(NSString *)key;
    + (NSDictionary *)queryPasswordDefination:(NSString *)key;
    + (OSStatus)saveUsername:(NSString *)username andPassword:(NSString *)password
                      forKey:(NSString *)key;

    + (OSStatus)savePassword:(NSString *)password forKey:(NSString *)key;
    + (OSStatus)saveUsername:(NSString *)username forKey:(NSString *)key;

    + (void)deleteSavedPasswordForKey:(NSString *)key;
    + (void)deleteKey:(NSString *)key;

@end

#endif
