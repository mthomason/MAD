//
//  MTPageCaching.h
//  MAD
//
//  Created by Michael Thomason on 5/8/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTPageCaching : NSObject

- (NSArray *)objectsForPage:(NSUInteger)index;
- (void)cacheObjects:(NSArray *)objects forPage:(NSUInteger)index;
- (void)dumpCache;
- (void)trimCache:(NSUInteger)index;

@end
