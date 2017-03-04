//
//  MADCredential.m
//  MAD
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADCredential.h"
#import <Foundation/NSString.h>

@implementation MADCredential

- (instancetype)initWithUsername:(NSString *)username andPassword:(NSString *)password {
    if (self = [super init]) {

        NSString *u = [[NSString alloc] initWithString:username];
        self.username = u;
        
        NSString *p = [[NSString alloc] initWithString:password];
        self.password = p;
        
    }
    return self;
    
}

- (id)copyWithZone:(nullable NSZone *)zone {
    id username = [self.username copyWithZone:zone];
    id password = [self.password copyWithZone:zone];
    id copy = [[[self class] alloc] initWithUsername:username andPassword:password];
    return copy;
}

@end
