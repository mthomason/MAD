//
//  MADArrayCaching.h
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_MTArrayCached_h
#define MAD_MTArrayCached_h

#import <Foundation/NSEnumerator.h>

@protocol MADCacheProtocol;

typedef NS_ENUM(int16_t, MADArrayCachingState) {
	MADArrayCachingStateInital = 2,
	MADArrayCachingStateLoading = 3,
	MADArrayCachingStateLoaded = 5,
	MADArrayCachingStateEmpty = 6,
};

@interface MADArrayCaching<ObjectType> : NSEnumerator<ObjectType>

	@property (nonatomic, readwrite, weak, nullable) id <MADCacheProtocol> cachedDelegate;
	@property (nonatomic, readonly, copy, nonnull) NSString * identifier;
	@property (readonly) NSUInteger count;
	@property (nonatomic, readonly, assign) MADArrayCachingState state;

	- (instancetype _Nonnull)initWithIdentifier:(nonnull NSString *)identifier
								 cachedDelegate:(nonnull id <MADCacheProtocol>)cachedDelegate
										  types:(nonnull NSSet<Class> *)classes;

	- (void)initializeDatabase;
	- (void)finalizeDatabase;

	- (nullable ObjectType)objectAtIndex:(NSUInteger)index;
	- (void)addObject:(id _Nonnull)object;
	- (BOOL)removeAllObjects;

	- (void)beginBulkInserts;
	- (void)endBulkInserts;

	- (id _Nullable)objectAtIndexedSubscript:(NSUInteger)idx;

@end

#endif
