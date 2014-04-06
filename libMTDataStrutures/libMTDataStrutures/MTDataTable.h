//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTDataTable : NSObject

@property (nonatomic, retain, readonly) NSMutableArray *table;

- (void)addObject:(id)object;
- (NSInteger)count;
- (id)objectAtIndex:(NSInteger)index;

@end
