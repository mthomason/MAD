//
//  DataColumn.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataColumn_h
#define Reports_MTDataColumn_h

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface MTDataColumn : NSObject
    <NSCoding>

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong) id defaultValue;

@property (nonatomic, copy) NSString *caption;
@property (nonatomic, copy) NSString *fieldName;
@property (nonatomic, strong) NSNumber *columnType;
@property (nonatomic, strong) NSNumber *nativeColumnType;
@property (nonatomic, strong) NSNumber *dataLength;
@property (nonatomic, strong) NSNumber *dataPercision;
@property (nonatomic, assign, getter = isPrimaryKey) BOOL primaryKey;
@property (nonatomic, assign, getter = isNotNull) BOOL notNull;
@property (nonatomic, assign, getter = isAutoIncrement) BOOL autoIncrement;

- (instancetype)initWithIdentifier:(NSString *)identifier;  //Init with a caption
- (instancetype)initWithPlist:(id)plist;

- (NSDictionary *)plist;
- (void)removeAllObjects;

- (void)addObject:(id)object;               //Adds to end of column data
- (instancetype)objectAtIndex:(NSInteger)index;       //Object at row number
- (void)addRows:(NSUInteger)count;          //Adds specifc number of rows with default value.

@end

#endif
