//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTDataTableLocation;

@interface MTDataTable : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *table;

//- (NSUInteger)count;
- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

- (void)addRow:(NSArray *)row;
- (id)objectAtIndex:(NSInteger)index;
- (id)value:(MTDataTableLocation *)location;

@end
