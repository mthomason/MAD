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
#import <MADFileManager/MADFileManager.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>
#import <MADSqlite3/MADSqlite3.h>
#import <MADDataStructures/MADDataStructures.h>
#import <MADFoundation/MTCacheProtocol.h>

@interface MADArrayCaching : NSEnumerator

@property (nonatomic, weak) id <MTCacheProtocol> cachedDelegate;
@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, assign, readonly) NSUInteger count;

- (instancetype)initWithIdentifier:(NSString *)identifier;
- (instancetype)initWithIdentifier:(NSString *)identifier cachedDelegate:(id<MTCacheProtocol>)cachedDelegate;

- (NSURL *)url;
- (id)objectAtIndex:(NSUInteger)index;
- (void)addObject:(id)object;
- (void)removeAllObjects;

- (void)beginBulkInserts;
- (void)endBulkInserts;

+ (NSURL *)urlForIdentifier:(NSString *)identifer;

- (void)resetEnumerator;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end

#endif
