//
//  MTPageCaching.h
//  MAD
//
//  Created by Michael Thomason on 5/8/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTPageCaching_h
#define Reports_MTPageCaching_h

#import <Foundation/NSObject.h>

@interface MTPageCaching : NSObject

- (NSArray *)objectsForPage:(NSUInteger)index;
- (void)cacheObjects:(NSArray *)objects forPage:(NSUInteger)index;
- (void)dumpCache;
- (void)trimCache:(NSUInteger)index;

@end

#endif
