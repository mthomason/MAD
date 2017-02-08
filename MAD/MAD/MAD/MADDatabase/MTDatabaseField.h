//
//  MNSDatabaseField.h
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseField_h
#define Reports_MTDatabaseField_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

@interface MTDatabaseField : NSObject
    <NSCopying>
    
    - (instancetype)initWithName:(NSString *)name;

    @property (nonatomic, copy) NSString *name;
    @property (nonatomic, assign) NSUInteger calculatedWidth;

    @property (nonatomic, assign) MADDataType fieldType;
    @property (nonatomic, assign) int64_t width;
    @property (nonatomic, assign) int16_t decimals;
    @property (nonatomic, assign) int16_t fieldTypeNative;
    @property (nonatomic, assign) BOOL primaryKey;

    - (BOOL)isNumeric;
    + (BOOL)isNumeric:(MADDataType)dataType;

    - (SEL)selectorForSorting;

@end

#endif
