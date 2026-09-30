//
//  MADDataTableLocation.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/7/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDataTableLocation_h
#define Reports_MADDataTableLocation_h

#import <Foundation/NSObject.h>

@interface MADDataTableLocation : NSObject
	<NSCoding>

	@property (nonatomic, assign) NSUInteger column;
	@property (nonatomic, assign) NSUInteger row;

	+ (instancetype)newDataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column;

@end

#endif
