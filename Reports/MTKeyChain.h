//
//  MTKeyChain.h
//  Reports
//
//  Created by Michael Thomason on 8/5/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTKeyChain : NSObject

+ (MTKeyChain *)sharedObject;

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forKey:(NSString *)key shortCircuit:(BOOL)shortCircuit completion:(void(^)(BOOL success, NSError *error))completion;
- (void)getUsernameAndPasswordForKey:(NSString *)key
                          completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain))completion;

@end
