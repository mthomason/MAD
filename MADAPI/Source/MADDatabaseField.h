//
//  MNSDatabaseField.h
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDatabaseField_h
#define Reports_MADDatabaseField_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

@interface MADDatabaseField : NSObject <NSCopying, NSSecureCoding>

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
