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
	MADArrayCachingStateUnknown = 0,
	MADArrayCachingStateInital = 2,
	MADArrayCachingStateLoading = 3,
	MADArrayCachingStateLoaded = 5,
	MADArrayCachingStateEmpty = 6,
};

static inline NSString * _Nonnull NSStringFromMADArrayCachingState(MADArrayCachingState);
static inline  NSString * _Nonnull NSStringFromMADArrayCachingState(MADArrayCachingState value) {
	switch (value) {
		case MADArrayCachingStateInital: return @"MADArrayCachingStateInital";
		case MADArrayCachingStateLoading: return @"MADArrayCachingStateLoading";
		case MADArrayCachingStateLoaded: return @"MADArrayCachingStateLoaded";
		case MADArrayCachingStateEmpty: return @"MADArrayCachingStateEmpty";
		case MADArrayCachingStateUnknown: default: return @"MADArrayCachingStateUnknown";
	}
}

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
