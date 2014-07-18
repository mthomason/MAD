//
//  MTArrayCached.h
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTArrayCached_h
#define MAD_MTArrayCached_h

#import <Foundation/Foundation.h>
#import "MTCacheProtocol.h"

@interface MTArrayCached : NSEnumerator

@property (nonatomic, weak) id <MTCacheProtocol> cachedDelegate;
@property (nonatomic, strong, readonly) NSString *identifier;

- (id)initWithIdentifier:(NSString *)identifier;
- (id)initWithIdentifier:(NSString *)identifier cachedDelegate:(id<MTCacheProtocol>)cachedDelegate;

- (NSURL *)url;
- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)count;
- (void)addObject:(id)object;
- (void)removeAllObjects;

- (void)beginBulkInserts;
- (void)endBulkInserts;

+ (NSURL *)urlForIdentifier:(NSString *)identifer;

- (void)resetEnumerator;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end

#endif
