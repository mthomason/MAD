//
//  MADErrorUserInfo.m
//  MAD
//
//  Created by Michael Thomason on 3/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADErrorUserInfo.h"

@interface MADErrorUserInfo ()

@property (nonatomic, strong, readwrite) NSDictionary *userinfo;

@end

@implementation MADErrorUserInfo

- (instancetype)initWithTitle:(NSString *)title andMessage:(NSString *)message {
    if (self = [super init]) {
        NSString *m = message == nil ? @"" : [NSString stringWithString:message];
        NSString *t = title == nil ? @"" : [NSString stringWithString:title];
        NSDictionary *userinfo = [[NSDictionary alloc] initWithObjectsAndKeys: t, NSLocalizedDescriptionKey, m, NSLocalizedFailureReasonErrorKey, nil];
        self.userinfo = userinfo;
    }
    return self;
}

- (NSError *)errorWithDomain: (NSString *)domain code: (NSInteger)code {
    return [NSError errorWithDomain:domain code:code userInfo:self.userinfo];
}

@end
