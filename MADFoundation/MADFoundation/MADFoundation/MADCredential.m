//
//  MADCredential.m
//  MAD
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <MADFoundation/MADCredential.h>
#import <Foundation/NSString.h>

@implementation MADCredential

- (instancetype)initWithUsername:(NSString *)username andPassword:(NSString *)password {
    if (self = [super init]) {

        _username = username.copy;
        _password = password.copy;
        
    }
    return self;
    
}

- (id)copyWithZone:(nullable NSZone *)zone {
    id username = [_username copyWithZone:zone];
    id password = [_password copyWithZone:zone];
    id copy = [[[self class] alloc] initWithUsername:username andPassword:password];
    return copy;
}

@end
