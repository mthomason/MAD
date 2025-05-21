//
//  MADDatabaseConnection.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseConnection.h"

#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSException.h>

@interface MADDatabaseConnection()
	@property (readwrite, nonatomic, assign) MADDatabaseType databaseType;
	@property (readwrite, nonatomic, copy) NSString *connectionString;
	@property (readwrite, nonatomic, assign) BOOL requiresCredentials;
	@property (readwrite, nonatomic, copy) NSString *identifier;
@end

@implementation MADDatabaseConnection

@synthesize databaseType = _databaseType;
@synthesize requiresCredentials = _requiresCredentials;
@synthesize connectionString = _connectionString;
@synthesize identifier = _identifier;

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
	typeof(self) copy = [[[self class] allocWithZone:zone] init];
	copy->_databaseType = _databaseType;
	copy->_connectionString = [_connectionString copy];
	copy->_requiresCredentials = _requiresCredentials;
	copy->_identifier = [_identifier copy];
	return copy;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self) {
		// Decode properties using instance variables
		_databaseType = [decoder decodeIntegerForKey:@"databaseType"];
		_connectionString = [decoder decodeObjectOfClass:[NSString class] forKey:@"connectionString"];
		_requiresCredentials = [decoder decodeBoolForKey:@"requiresCredentials"];
		_identifier = [decoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	// Encode properties using instance variables
	[coder encodeInteger:_databaseType forKey:@"databaseType"];
	[coder encodeObject:_connectionString forKey:@"connectionString"];
	[coder encodeBool:_requiresCredentials forKey:@"requiresCredentials"];
	[coder encodeObject:_identifier forKey:@"identifier"];
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
