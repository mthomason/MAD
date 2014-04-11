//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTDataColumn, MTDataTableLocation;

@interface MTDataTable : NSObject
    <NSCoding>

@property (nonatomic, strong, readonly) NSMutableArray *table;
@property (nonatomic, strong, readonly) NSMutableArray *columnKeys;
@property (nonatomic, strong, readonly) NSMutableDictionary *columns;
//@property (nonatomic, strong, readonly) NSMutableArray *sortIndex;

- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns;
- (id)initWithPlist:(id)plist;
- (id)plist;

- (void)addColumn:(MTDataColumn *)column;
- (void)addRow:(NSArray *)row;
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row;

- (id)objectAtIndex:(NSInteger)index;
- (id)value:(MTDataTableLocation *)location;

- (NSDictionary *)dataForRow:(NSUInteger)row;
- (NSArray *)sortedRepresentationUsingDescriptors:(NSArray *)sortDescriptors;

- (NSUInteger)count;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

@end
