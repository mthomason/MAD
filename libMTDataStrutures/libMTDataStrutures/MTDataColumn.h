//
//  DataColumn.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTDataColumn : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong) id defaultValue;

- (id)initWithIdentifier:(NSString *)identifier;  //Init with a caption
- (void)addObject:(id)object;               //Adds to end of column data
- (id)objectAtIndex:(NSInteger)index;       //Object at row number
- (void)addRows:(NSUInteger)count;          //Adds specifc number of rows with default value.

@end
