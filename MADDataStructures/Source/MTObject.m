//
//  MTObject.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/11/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTObject.h"
#import <Foundation/NSString.h>

@interface MTObject ()

@property (readwrite, nonatomic, strong) NSObject <NSCopying> *object;

@end

@implementation MTObject

+ (instancetype)newObject:(NSObject <NSCopying> *)object {
	return [[MTObject alloc] initWithObject:object];
}

- (instancetype)init {
	return [self initWithObject:nil];
}

- (instancetype)initWithObject:(NSObject <NSCopying> *)object {
	if (self = [super init]) {
		_object = [object copyWithZone:nil];
	}
	return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
	id copy = [[[self class] allocWithZone:zone] init];
	((typeof(self)) copy).object = [self.object copyWithZone:zone];
	return copy;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
	BOOL result;
	if ([self.object conformsToProtocol:@protocol(MTProtocolCompare)]) {
		result = [(id <MTProtocolCompare>)self.object isEqualTo:sender];
	} else {
		result = [self.object isEqual:sender];
	}
	return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
	return [(id <MTProtocolLog>)self.object toStringHumanReadable];
}

- (NSString *)toString {
	return [(id <MTProtocolLog>)self.object toString];
}

- (NSString *)toStringDebug {
	return [NSString stringWithFormat:@"%@", self.object];
}

@end
