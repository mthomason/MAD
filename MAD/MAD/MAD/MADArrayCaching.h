//
//  MTArrayCached.h
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTArrayCached_h
#define MAD_MTArrayCached_h

#import <Foundation/NSEnumerator.h>
#import <MADFoundation/MTCacheProtocol.h>

@interface MADArrayCaching<ObjectType> : NSEnumerator

    @property (nonatomic, weak) id <MTCacheProtocol> _Nullable cachedDelegate;
    @property (nonatomic, strong, readonly) NSString * _Nonnull identifier;
    @property (readonly) long long int count;

    - (instancetype _Nonnull)initWithIdentifier:(NSString * _Nonnull)identifier;
    - (instancetype _Nonnull)initWithIdentifier:(NSString * _Nonnull)identifier cachedDelegate:(id <MTCacheProtocol> _Nullable)cachedDelegate;

    - (void)initializeDatabase;
    - (void)finalizeDatabase;

    - (NSURL * _Nullable)url;
    - (nullable ObjectType)objectAtIndex:(NSUInteger)index;
    - (void)addObject:(id _Nonnull)object;
    - (void)removeAllObjects;

    - (void)beginBulkInserts;
    - (void)endBulkInserts;

    + (NSURL * _Nullable)urlForIdentifier:(NSString * _Nonnull)identifer;

    - (void)resetEnumerator;
    - (id _Nullable)objectAtIndexedSubscript:(NSUInteger)idx;

@end

#endif
