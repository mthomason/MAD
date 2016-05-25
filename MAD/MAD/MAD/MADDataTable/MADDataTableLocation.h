//
//  MTDataTableLocation.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTableLocation_h
#define Reports_MTDataTableLocation_h

#import <Foundation/NSObject.h>

@interface MADDataTableLocation : NSObject
    <NSCoding>

    @property (nonatomic, assign) NSUInteger column;
    @property (nonatomic, assign) NSUInteger row;

    + (instancetype)newDataTableLocationForRow:(NSUInteger)row
                                      inColumn:(NSUInteger)column;

@end

#endif
