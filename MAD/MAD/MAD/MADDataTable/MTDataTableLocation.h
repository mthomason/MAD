//
//  MTDataTableLocation.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTableLocation_h
#define Reports_MTDataTableLocation_h

#import <Foundation/Foundation.h>

@interface MTDataTableLocation : NSObject
    <NSCoding>

@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, assign) NSUInteger row;

+ (instancetype)dataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column;

@end

#endif
