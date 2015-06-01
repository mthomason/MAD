//
//  MTMath.h
//  MAD
//
//  Created by Michael Thomason on 7/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTMath_h
#define Reports_MTMath_h

#import <Foundation/Foundation.h>

@interface MTMath : NSObject

+ (NSInteger)getRandomNumberBetween:(NSInteger)from to:(NSInteger)to;

+ (NSNumber *)systemFileSizeToMB:(unsigned long long)sfs;

@end

#endif
