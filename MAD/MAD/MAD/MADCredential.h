//
//  MADCredential.h
//  MAD
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADCredential_h
#define MAD_MADCredential_h

#import <Foundation/NSObject.h>

typedef NS_ENUM(short, MADCredentialSource) {
    unknown,
    none,
    keychain,
    credential_prompt,
    password_prompt,
};

@interface MADCredential : NSObject <NSCopying>

- (instancetype)initWithUsername:(NSString *)username andPassword:(NSString *)password;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@end

@protocol MADOperationHoldsCredentialsProtocol <NSObject>

    @property (nonatomic, readonly, copy) MADCredential *credentials;
    @property (nonatomic, readonly, assign) bool gotCredentials;

@end

#endif
