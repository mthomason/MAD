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

	- (instancetype)init NS_DESIGNATED_INITIALIZER;

	@property (nonatomic, strong, readwrite) MADResult *value;
	@property (nonatomic, assign, readwrite) MADDataType datatype;
	@property (nonatomic, assign, readwrite) NSUInteger fieldIndex;

@end

@implementation MADDatabaseDataBinding

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
		
		if (value == nil) {
			datatype = MADDataTypeNull;
			value = [NSNull null];
		} else if ([value isKindOfClass:[NSNull class]]) {
			datatype = MADDataTypeNull;
		} else {
			datatype = DataTypeLimited(datatype);
			if (datatype == MADDataTypeUnknown) {
				value = [[NSString alloc] initWithFormat:@"%@", value];
				datatype = MADDataTypeString;
			} else {
				self.value = [value copy];
			}
		}
		self.datatype = datatype;
		self.fieldIndex = (int)fieldIndex;
	}
	return self;
}

- (NSUInteger)columnNumber {
	return self.fieldIndex + 1;
}

@end
