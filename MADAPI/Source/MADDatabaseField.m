//
//  MNSDatabaseField.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseField.h"
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/NSData+Comparison.h>

#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <string.h>
#import <MADFoundation/madlog.h>

static inline BOOL isDataTypeNumeric(MADDataType);
static inline BOOL isDataTypeNumeric(MADDataType type) {
	switch (type) {
		case MADDataTypeBit:
		case MADDataTypeFloat:
		case MADDataTypeInteger:
		case MADDataTypeNumber:
		case MADDataTypeDecimal:
		case MADDataTypeDouble:
		case MADDataTypeEnum:
		case MADDataTypeInt24:
		case MADDataTypeLong:
		case MADDataTypeLongLong:
		case MADDataTypeShort:
			return YES;
			break;
		case MADDataTypeBlob:
		case MADDataTypeDate:
		case MADDataTypeDateTime:
		case MADDataTypeGeometry:
		case MADDataTypeImage:
		case MADDataTypeSet:
		case MADDataTypeString:
		case MADDataTypeTime:
		case MADDataTypeTimeStamp:
		case MADDataTypeYear:
		case MADDataTypeUnknown:
		case MADDataTypeVarChar:
		default:
			return NO;
			break;
	}
}

@implementation MADDatabaseField

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding { return YES; }

#pragma mark - Initialization

- (instancetype)initWithName:(NSString *)name {
	if (self = [self init]) {
		_name = [name copy];
		_calculatedWidth = 0;
		_fieldType = MADDataTypeUnknown;
		_width = 0;
		_decimals = 0;
		_fieldTypeNative = 0;
		_primaryKey = NO;
	}
	return self;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	MADDatabaseField *copy = [[[self class] allocWithZone:zone] init];
	if (copy) {
		copy.name = [_name copy];
		copy.calculatedWidth = _calculatedWidth;
		copy.fieldType = _fieldType;
		copy.fieldTypeNative = _fieldTypeNative;
		copy.width = _width;
		copy.decimals = _decimals;
		copy.primaryKey = _primaryKey;
	}
	return copy;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_name forKey:NSStringFromSelector(@selector(name))];

	NSUInteger calculatedWidth = _calculatedWidth;
	[coder encodeBytes:(const void *)&calculatedWidth length:sizeof(NSUInteger) forKey:NSStringFromSelector(@selector(calculatedWidth))];
	
	[coder encodeInt64:_width forKey:NSStringFromSelector(@selector(width))];
	[coder encodeInt:_fieldType forKey:NSStringFromSelector(@selector(fieldType))];
	[coder encodeInt:_decimals forKey:NSStringFromSelector(@selector(decimals))];
	[coder encodeInt:_fieldTypeNative forKey:NSStringFromSelector(@selector(fieldTypeNative))];
	[coder encodeBool:_primaryKey forKey:NSStringFromSelector(@selector(primaryKey))];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [self init]) {
		_name = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(name))];

		NSUInteger calculatedWidth = 0;
		NSUInteger returnedLength = 0;
		const uint8_t *bytes = [decoder decodeBytesForKey:NSStringFromSelector(@selector(calculatedWidth)) returnedLength:&returnedLength];
		if (returnedLength == sizeof(NSUInteger) && bytes != NULL) {
			memcpy(&calculatedWidth, bytes, sizeof(NSUInteger));
			self.calculatedWidth = calculatedWidth; // Assign to your property
		} else {
			os_log_error(OS_LOG_DEFAULT, "Error decoding calculatedWidth");
		}
		
		_width = [decoder decodeInt64ForKey:@"width"];
		_fieldType = (MADDataType)[decoder decodeIntForKey:@"fieldType"];
		_decimals = [decoder decodeIntForKey:@"decimals"];
		_fieldTypeNative = [decoder decodeIntForKey:@"fieldTypeNative"];
		_primaryKey = [decoder decodeBoolForKey:@"primaryKey"];
	}
	return self;
}

#pragma mark - NSObject

- (NSString *)description {
	return [NSString stringWithFormat:
			@"<%@: %p> name: %@, fieldType: %ld, width: %lld, decimals: %d, nativeType: %d, primaryKey: %@, calculatedWidth: %lu",
			NSStringFromClass([self class]), self, _name, (long)_fieldType, _width, _decimals, _fieldTypeNative, _primaryKey ? @"YES" : @"NO", (unsigned long)_calculatedWidth];
}

#pragma mark - Public Methods

- (BOOL)isNumeric { return isDataTypeNumeric(_fieldType); }

+ (BOOL)isNumeric:(MADDataType)dataType { return isDataTypeNumeric(dataType); }

- (SEL)selectorForSorting { return MADDataTypeSelectorForSorting(self.fieldType); }

@end
