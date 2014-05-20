//
//  MNSDatabaseField.h
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseField_h
#define Reports_MTDatabaseField_h

typedef NS_ENUM(NSUInteger, MTDataType) {
    MTDataTypeBit           = 0,
    MTDataTypeBlob          = 1,
    MTDataTypeDate          = 2,
    MTDataTypeDateTime      = 3,
    MTDataTypeFloat         = 5,
    MTDataTypeGeometry      = 6,
	MTDataTypeImage         = 7,
    MTDataTypeInteger       = 8,
	MTDataTypeNumber        = 9,
    MTDataTypeSet           = 10,
	MTDataTypeString        = 11,
    MTDataTypeTime          = 12,
    MTDataTypeTimeStamp     = 13,
    MTDataTypeYear          = 14,
    MTDataTypeUnknown       = 15,
    MTDataTypeDecimal       = 16,
    MTDataTypeDouble        = 17,
    MTDataTypeEnum          = 18,
    MTDataTypeInt24         = 19,
    MTDataTypeLong          = 20,
    MTDataTypeLongLong      = 21,
    MTDataTypeVarChar       = 22,
    MTDataTypeShort         = 23,
    MTDataTypeNull          = 24
};

#import <Foundation/Foundation.h>

@interface MTDatabaseField : NSObject

- (id)initWithName:(NSString *)name;

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, assign) MTDataType fieldType;
@property (nonatomic, assign) NSInteger fieldTypeNative;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger decimals;
@property (nonatomic, assign) NSUInteger calculatedWidth;
@property (nonatomic, assign) BOOL primaryKey;

- (BOOL)isNumeric;
+ (BOOL)isNumeric:(MTDataType)dataType;

- (SEL)selectorForSorting;
+ (SEL)selectorForSorting:(MTDataType)dataType;

@end

#endif
