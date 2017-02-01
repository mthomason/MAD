//
//  MADDataColumn.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDataColumn_h
#define Reports_MADDataColumn_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADDataType.h>

@class NSMutableDictionary;

@interface MADDataColumn : NSObject
    <NSCoding>

    @property (nonatomic, readonly, copy) NSString *identifier;

    @property (nonatomic, readwrite, strong) NSObject <NSCopying> *defaultValue;

    @property (nonatomic, assign)   MADDataType  type;
    @property (nonatomic, assign)   int16_t     nativeType;
    @property (nonatomic, assign)   int64_t     dataLength;
    @property (nonatomic, assign)   int32_t     dataPercision;
    
    @property (nonatomic, copy)     NSString    *caption;
    @property (nonatomic, copy)     NSString    *fieldName;

    @property (nonatomic, assign, getter = isPrimaryKey) BOOL primaryKey;
    @property (nonatomic, assign, getter = isNotNull) BOOL notNull;
    @property (nonatomic, assign, getter = isAutoIncrement) BOOL autoIncrement;

    - (instancetype)initWithIdentifier:(NSString *)identifier;  //Init with a caption
    - (instancetype)initWithPlist:(NSDictionary *)plist;
    - (instancetype)initWithType:(MADDataType)columnType
                            name:(NSString *)name
                          number:(int)columnNumber
                         dataLen:(int)dataLength
                     indexOfType:(int)indexOfType
                          length:(NSInteger)length
                       percision:(int32_t)percision
                      nativeType:(int16_t)nativeType;

    - (NSDictionary *)copyPlist;
    - (void)removeAllObjects;

    - (void)addObject:(id)object;                       //Adds to end of column data
    - (instancetype)objectAtIndex:(NSUInteger)index;    //Object at row number
    - (void)addRows:(NSUInteger)count;                  //Adds specifc number of rows with default.

    + (MADDataColumn *)newDataColumnWithIdentifier:(NSString *)identifier;

@end

#endif
