//
//  MADMapStrings.h
//  MADDataStructures
//
//  Created by Michael on 1/1/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MADMapStrings_h
#define MAD_DataStructures_MADMapStrings_h

#import <Foundation/NSObject.h>

@class NSString;

@interface MADMapStrings : NSObject

    - (unsigned long)count;
    - (void)setObject:(NSString *)str toKey:(short)key;
    - (NSString *)objectAtIndex:(short)i;

@end

#endif
