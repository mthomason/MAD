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

    @property (nonatomic, assign) MTDataType fieldType;
    @property (nonatomic, assign) NSInteger fieldTypeNative;
    @property (nonatomic, assign) NSUInteger width;
    @property (nonatomic, assign) NSUInteger decimals;
    @property (nonatomic, assign) BOOL primaryKey;

    - (BOOL)isNumeric;
    + (BOOL)isNumeric:(MTDataType)dataType;

    - (SEL)selectorForSorting;

@end

#endif
