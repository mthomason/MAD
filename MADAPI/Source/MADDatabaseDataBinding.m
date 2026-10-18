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
#import <Foundation/NSCalendar.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSValue.h>
#import <string.h>
#import <MADFoundation/madlog.h>
#import <dispatch/dispatch.h>

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

//  The date/time family stores as the epoch number (REAL): the class the report's
//  display path already reads (RptqDocumentElement value formatting).  The
//  family's limited type is String, so the declared type is checked before
//  limiting.
static inline BOOL MADDataTypeIsDateFamily(MADDataType);
static inline BOOL MADDataTypeIsDateFamily(MADDataType dataType) {
	switch (dataType) {
		case MADDataTypeDate:
		case MADDataTypeDateTime:
		case MADDataTypeTime:
		case MADDataTypeTimeStamp:
			return YES;
		default:
			return NO;
	}
}

//  One log line per (declared type, value class) pair per process: a value
//  outside its column's canonical class is worth hearing about, not once per row.
static void MADBindingLogViolation(MADDataType declaredType, Class valueClass, NSString *resolution) {
	static NSMutableSet *loggedViolations;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		loggedViolations = [[NSMutableSet alloc] init];
	});
	NSString *key = [[NSString alloc] initWithFormat:@"%d:%@", (int)declaredType, NSStringFromClass(valueClass)];
	@synchronized (loggedViolations) {
		if (![loggedViolations containsObject:key]) {
			[loggedViolations addObject:key];
			os_log_error(OS_LOG_DEFAULT, "%s: a %@ value in a %@ column is not the column's canonical class; %@.",
						 __PRETTY_FUNCTION__, NSStringFromClass(valueClass), NSStringFromMADDataType(declaredType), resolution);
		}
	}
}

//  The canonical cache value for a column: one class per declared type, decided
//  here so the sqlite binder never meets a value outside it (BUGS.md,
//  "MADReportFormatter compares untyped values through id").  A value the type
//  can represent is converted or kept; one it cannot is stored NULL with a
//  one-time log -- never silently as another class, and never a crash.
static id MADCanonicalValueForType(MADResult *value, MADDataType datatype, MADDataType declaredType) {
	switch (datatype) {
		case MADDataTypeInteger: {
			if ([value isKindOfClass:[NSNumber class]]) return [value copy];
			if ([value isKindOfClass:[NSString class]]) {
				MADBindingLogViolation(declaredType, [value class], @"parsing the number");
				return [[NSNumber alloc] initWithLongLong:((NSString *)value).longLongValue];
			}
			break;
		}
		case MADDataTypeFloat:
		case MADDataTypeDouble: {
			if ([value isKindOfClass:[NSNumber class]]) return [value copy];
			if ([value isKindOfClass:[NSString class]]) {
				MADBindingLogViolation(declaredType, [value class], @"coercing the number");
				return [[NSNumber alloc] initWithDouble:((NSString *)value).doubleValue];
			}
			break;
		}
		case MADDataTypeString: {
			if (MADDataTypeIsDateFamily(declaredType)) {
				// The date family's canonical class is the epoch number, so a
				// date, its components, or an epoch string all become one.
				if ([value isKindOfClass:[NSNumber class]]) return [value copy];
				if ([value isKindOfClass:[NSDate class]]) {
					return [[NSNumber alloc] initWithDouble:((NSDate *)value).timeIntervalSince1970];
				}
				if ([value isKindOfClass:[NSDateComponents class]]) {
					NSDate *date = ((NSDateComponents *)value).date != nil ? ((NSDateComponents *)value).date :
					[[NSCalendar currentCalendar] dateFromComponents:(NSDateComponents *)value];
					return [[NSNumber alloc] initWithDouble:date.timeIntervalSince1970];
				}
				if ([value isKindOfClass:[NSString class]]) {
					MADBindingLogViolation(declaredType, [value class], @"parsing the epoch");
					return [[NSNumber alloc] initWithDouble:((NSString *)value).doubleValue];
				}
				break;
			}
			if ([value isKindOfClass:[NSString class]]) return [value copy];
			if ([value isKindOfClass:[NSNumber class]]) {
				MADBindingLogViolation(declaredType, [value class], @"storing its text");
				return [[NSString alloc] initWithFormat:@"%@", value];
			}
			break;
		}
		case MADDataTypeBlob: {
			if ([value isKindOfClass:[NSData class]]) return [value copy];
			if ([value isKindOfClass:[NSString class]]) {
				// A string the UTF-8 encoder cannot represent (an unpaired
				// surrogate) answers nil; store NULL with the log below rather
				// than a nil value.
				NSData *data = [((NSString *)value) dataUsingEncoding:NSUTF8StringEncoding];
				if (data != nil) {
					MADBindingLogViolation(declaredType, [value class], @"storing its UTF-8 bytes");
					return data;
				}
				break;
			}
			break;
		}
		default:
			break;
	}
	MADBindingLogViolation(declaredType, [value class], @"storing NULL");
	return [NSNull null];
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
			MADDataType declaredType = datatype;
			datatype = DataTypeLimited(datatype);
			if (datatype == MADDataTypeUnknown) {
				self.value = [[NSString alloc] initWithFormat:@"%@", value];
				datatype = MADDataTypeString;
			} else {
				// The canonical class for the column's declared type, so the
				// binder can trust the pair it is handed (BUGS.md, the
				// untyped-compare entry).
				self.value = MADCanonicalValueForType(value, datatype, declaredType);
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
