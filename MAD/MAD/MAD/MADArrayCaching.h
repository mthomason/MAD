//
//  MADArrayCaching.h
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTArrayCached_h
#define MAD_MTArrayCached_h

#import <Foundation/NSEnumerator.h>

@protocol MTCacheProtocol;

@interface MADArrayCaching<ObjectType> : NSEnumerator

    @property (nonatomic, readwrite, weak, nullable) id <MTCacheProtocol> cachedDelegate;
    @property (nonatomic, readonly, copy, nonnull) NSString * identifier;
    @property (readonly) long long int count;

    - (instancetype _Nonnull)initWithIdentifier:(nonnull NSString *)identifier
                                 cachedDelegate:(id <MTCacheProtocol> _Nullable)cachedDelegate;

    - (void)initializeDatabase;
    - (void)finalizeDatabase;

    - (nullable ObjectType)objectAtIndex:(NSUInteger)index;
    - (void)addObject:(id _Nonnull)object;
    - (void)removeAllObjects;

    - (void)beginBulkInserts;
    - (void)endBulkInserts;

    - (id _Nullable)objectAtIndexedSubscript:(NSUInteger)idx;

@end

#endif
