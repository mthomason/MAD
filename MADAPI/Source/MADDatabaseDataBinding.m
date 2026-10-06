//
//  MADDatabaseDataBinding.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseDataBinding.h"

#import <MADFoundation/MADDataType.h>

#import <Foundation/NSNull.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSValue.h>
#import <string.h>
#import <MADFoundation/madlog.h>

static inline MADDataType DataTypeLimited(MADDataType);
static inline MADDataType DataTypeLimited(MADDataType expandedDataType) {
	switch (expandedDataType) {
		case MADDataTypeBit:
		case MADDataTypeInteger:
		case MADDataTypeShort:
		case MADDataTypeLong:
		case MADDataTypeLongLong:
		case MADDataTypeInt24:
		case MADDataTypeEnum: {
			return MADDataTypeInteger;
			break;
		}
		case MADDataTypeSet:
		case MADDataTypeTime:
		case MADDataTypeTimeStamp:
		case MADDataTypeYear:
		case MADDataTypeDate:
		case MADDataTypeDateTime:
		case MADDataTypeString:
		case MADDataTypeVarChar:
		case MADDataTypeGeometry: {
			return MADDataTypeString;
			break;
		}
		case MADDataTypeImage:
		case MADDataTypeBlob: {
			return MADDataTypeBlob;
			break;
		}
		case MADDataTypeFloat: {
			return MADDataTypeFloat;
			break;
		}
		case MADDataTypeDouble:
		case MADDataTypeDecimal:
		case MADDataTypeNumber: {
			return MADDataTypeDouble;
			break;
		}
		case MADDataTypeUnknown:
		default: {
			return MADDataTypeUnknown;
			break;
		}
	}
}

@interface MADDatabaseDataBinding ()

@property (nonatomic, strong, readwrite) MADResult *value;
@property (nonatomic, assign, readwrite) MADDataType datatype;
@property (nonatomic, assign, readwrite) NSUInteger fieldIndex;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@implementation MADDatabaseDataBinding

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
	return YES;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
	NSUInteger fieldIndex = _fieldIndex;
	[coder encodeBytes:(const void *)&fieldIndex length:sizeof(NSUInteger) forKey:NSStringFromSelector(@selector(fieldIndex))];
	[coder encodeObject:_value forKey:NSStringFromSelector(@selector(value))];
	[coder encodeInt:_datatype forKey:NSStringFromSelector(@selector(datatype))];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [self init]) {
		NSUInteger fieldIndex = 0;
		NSUInteger returnedLength = 0;
		const uint8_t *bytes = [decoder decodeBytesForKey:NSStringFromSelector(@selector(fieldIndex)) returnedLength:&returnedLength];
		if (returnedLength == sizeof(NSUInteger) && bytes != NULL) {
			memcpy(&fieldIndex, bytes, sizeof(NSUInteger));
			_fieldIndex = fieldIndex;
		} else {
			os_log_error(OS_LOG_DEFAULT, "Error decoding calculatedWidth");
		}
		NSError *error = nil;
		_value = [decoder decodeTopLevelObjectOfClasses: [NSSet setWithObjects:[NSNull class], [NSString class], [NSNumber class], [NSData class], [NSDate class], nil]
												 forKey: NSStringFromSelector(@selector(value))
												  error: &error];
		if (error != nil) {
			os_log_error(OS_LOG_DEFAULT, "%s: Error decoding fieldIndex: %@", __PRETTY_FUNCTION__, error);
		}
		_datatype = (MADDataType)[decoder decodeIntForKey:NSStringFromSelector(@selector(datatype))];
	}
	return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	MADDatabaseDataBinding *copy = [[[self class] allocWithZone:zone] init];
	if (copy) {
		copy->_value = [_value copy];
		copy->_fieldIndex = _fieldIndex;
		copy->_datatype = _datatype;
	}
	return copy;
}

#pragma mark - Initialization

- (instancetype)init {
	if (self = [super init]) {
		self.value = nil;
		self.datatype = MADDataTypeNull;
		self.fieldIndex = 0;
	}
	return self;
}

- (instancetype)initWithDataType:(MADDataType)datatype
					  fieldIndex:(NSUInteger)fieldIndex
						   value:(MADResult *)value {

	if (self = [super init]) {
		
		if (value == nil || [value isKindOfClass:[NSNull class]]) {
			// Both "no value" spellings normalise to the same stored form. They used to
			// differ (nil stored [NSNull null], an explicit NSNull left value nil), which
			// was harmless only because the SQL bind path treats both as SQL NULL.
			datatype = MADDataTypeNull;
			self.value = [NSNull null];
		} else {
			datatype = DataTypeLimited(datatype);
			if (datatype == MADDataTypeUnknown) {
				self.value = [NSString stringWithFormat:@"%@", value];
				datatype = MADDataTypeString;
			} else {
				self.value = [value copy];
			}
		}
		self.datatype = datatype;
		self.fieldIndex = fieldIndex;
	}
	return self;
}

- (NSUInteger)columnNumber {
	return _fieldIndex + 1;
}

@end
