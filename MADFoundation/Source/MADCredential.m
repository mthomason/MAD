//
//  MADCredential.m
//  MAD
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <MADFoundation/MADCredential.h>
#import "madlog.h"
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

@implementation MADCredential

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)initWithUsername:(NSString *)username andPassword:(NSString *)password {
	if (self = [super init]) {
		if (!username || username.length <= 0) {
			os_log_info(GetFoundationLog(), "%s Username is nil or empty.", __PRETTY_FUNCTION__);
		}
		if (!password || password.length <= 0) {
			os_log_info(GetFoundationLog(), "%s Password is nil or empty.", __PRETTY_FUNCTION__);
		}
		_username = [username copy];
		_password = [password copy];
	}
	return self;
	
}

- (id)copyWithZone:(nullable NSZone *)zone {
	id copy = [[[self class] alloc] initWithUsername:self.username andPassword:self.password];
	return copy;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	NSString *decodedUsername = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(username))];
	NSString *decodedPassword = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(password))];
	return [self initWithUsername:decodedUsername andPassword:decodedPassword];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.username forKey:@"username"];
	[coder encodeObject:self.password forKey:@"password"];
}

@end
