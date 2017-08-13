//
//  MTKeyChain.h
//  Reports
//
//  Created by Michael Thomason on 8/5/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTKeyChain_h
#define MAD_MTKeyChain_h

#import <Foundation/NSObject.h>

extern NSString * const MTKeyChainUsernameAccountDesc;
extern NSString * const MTKeyChainPasswordAccountDesc;

@interface MTKeyChain : NSObject

    + (OSStatus)saveUsername:(NSString *)username
                 andPassword:(NSString *)password
                      forKey:(NSString *)key;

    + (OSStatus)savePassword:(NSString *)password forKey:(NSString *)key;
    + (OSStatus)saveUsername:(NSString *)username forKey:(NSString *)key;

    + (OSStatus)saveToken:(NSString *)token
                   forKey:(NSString *)key
          withDescription:(NSString *)description;

    + (NSDictionary *)queryDefination:(NSString *)key
                      withDescription:(NSString *)description;

    + (NSString *)newKeyForUsernameWithMainKey:(NSString *)key;
    + (NSString *)newKeyForPasswordWithMainKey:(NSString *)key;
    + (NSDictionary *)queryUsernameDefination:(NSString *)key;
    + (NSDictionary *)queryPasswordDefination:(NSString *)key;

    + (void)deleteKey:(NSString *)key;
    + (void)deleteSavedPasswordForKey:(NSString *)key error:(NSError * __autoreleasing *)error;

@end

#endif
