//
//  MTDataTableLocation.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTDataTableLocation : NSObject
    <NSCoding>

@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, assign) NSUInteger row;

+ (id)dataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column;

@end
