//
//  MADProgress.m
//  MAD
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADProgress.h"
#import <Foundation/NSString.h>

@interface MADProgress ()

	@property (nonatomic, copy, readwrite) NSString *message;
	@property (nonatomic, assign, readwrite) float progress;

@end

@implementation MADProgress

- (instancetype)initWithMessage:(NSString *)message andProgress:(float)progress {
	if (self = [super init]) {
		_message = message.copy;
		_progress = progress;
	}
	return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
	id message = [self.message copyWithZone:zone];
	id copy = [[[self class] alloc] initWithMessage:message andProgress:self.progress];
	return copy;
}

@end
