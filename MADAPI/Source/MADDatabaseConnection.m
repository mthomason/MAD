//
//  MADDatabaseConnection.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDatabaseConnection.h"
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSException.h>

@interface MADDatabaseConnection()
@property (readwrite, nonatomic, assign) BOOL requiresCredentials;
@property (readwrite, nonatomic, assign) MADDatabaseType databaseType;
@property (readwrite, nonatomic, copy) NSString *connectionString;
@property (readwrite, nonatomic, copy) NSString *identifier;
@end

@implementation MADDatabaseConnection

@synthesize databaseType = _databaseType;
@synthesize requiresCredentials = _requiresCredentials;
@synthesize connectionString = _connectionString;
@synthesize identifier = _identifier;

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding { return YES; }

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [self init]) {
		_databaseType = (MADDatabaseType)[decoder decodeIntegerForKey:NSStringFromSelector(@selector(databaseType))];
		_connectionString = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(connectionString))];
		_requiresCredentials = [decoder decodeBoolForKey:NSStringFromSelector(@selector(requiresCredentials))];
		_identifier = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(identifier))];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInteger:_databaseType forKey:NSStringFromSelector(@selector(databaseType))];
	[coder encodeObject:_connectionString forKey:NSStringFromSelector(@selector(connectionString))];
	[coder encodeBool:_requiresCredentials forKey:NSStringFromSelector(@selector(requiresCredentials))];
	[coder encodeObject:_identifier forKey:NSStringFromSelector(@selector(identifier))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
	typeof(self) copy = [[[self class] allocWithZone:zone] init];
	if (copy) {
		copy->_databaseType = _databaseType;
		copy->_connectionString = [_connectionString copy];
		copy->_requiresCredentials = _requiresCredentials;
		copy->_identifier = [_identifier copy];
	}
	return copy;
}

#pragma mark - Factory Class Design

+ (NSString *)Identifier {
	NSAssert(NO, @"This is a factory class.  Don't call this.");
	return nil;
}

#pragma mark - Dynamic Property Handling

- (MADDatabaseType)databaseType {
	[self throwExceptionForUnimplementedProperty:_cmd];
	return MADDatabaseTypeUnknown;
}

- (NSString *)connectionString {
	[self throwExceptionForUnimplementedProperty:_cmd];
	return nil;
}

- (BOOL)requiresCredentials {
	[self throwExceptionForUnimplementedProperty:_cmd];
	return NO;
}

- (NSString *)identifier {
	[self throwExceptionForUnimplementedProperty:_cmd];
	return nil;
}

- (void)throwExceptionForUnimplementedProperty:(SEL)selector {
	NSString *reason = [NSString stringWithFormat:@"Subclasses must implement %@", NSStringFromSelector(selector)];
	@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
}

@end
