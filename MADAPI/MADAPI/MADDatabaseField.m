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

- (instancetype)initWithName:(NSString *)name {
	if (self = [self init]) {
		_name = name.copy;
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
	copy.name = _name.copy;
	copy.calculatedWidth = _calculatedWidth;
	copy.fieldType = _fieldType;
	copy.fieldTypeNative = _fieldTypeNative;
	copy.width = _width;
	copy.decimals = _decimals;
	copy.primaryKey = _primaryKey;
	return copy;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeInteger:self.calculatedWidth forKey:@"calculatedWidth"];
	[coder encodeInt64:self.width forKey:@"width"];
	[coder encodeInt:self.fieldType forKey:@"fieldType"];
	[coder encodeInt:self.decimals forKey:@"decimals"];
	[coder encodeInt:self.fieldTypeNative forKey:@"fieldTypeNative"];
	[coder encodeBool:self.primaryKey forKey:@"primaryKey"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [self init]) {
		_name = [decoder decodeObjectForKey:@"name"];
		_calculatedWidth = [decoder decodeIntegerForKey:@"calculatedWidth"];
		_width = [decoder decodeInt64ForKey:@"width"];
		_fieldType = (MADDataType)[decoder decodeIntForKey:@"fieldType"];
		_decimals = [decoder decodeIntForKey:@"decimals"];
		_fieldTypeNative = [decoder decodeIntForKey:@"fieldTypeNative"];
		_primaryKey = [decoder decodeBoolForKey:@"primaryKey"];
	}
	return self;
}

#pragma mark - Public Methods

- (BOOL)isNumeric { return isDataTypeNumeric(_fieldType); }

+ (BOOL)isNumeric:(MADDataType)dataType { return isDataTypeNumeric(dataType); }

- (SEL)selectorForSorting {
	return MADDataTypeSelectorForSorting(self.fieldType);
}

@end
