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
#import <Foundation/NSSet.h>

@protocol MADCacheProtocol;

// The on-disk format of a .madac file: a single table named "ac" with an integer
// primary key "ci" (the element index) and a blob "ck" (the serialised element).
// Shared with MADArrayCachingEnumerator so the two stay on the same format.
NS_ASSUME_NONNULL_BEGIN
extern NSString * const MTArrayCachedTableName;
extern NSString * const MTArrayCachedColumnKey;
extern NSString * const MTArrayCachedColumnValue;
extern NSString * const MTArrayCachedExtension;
NS_ASSUME_NONNULL_END

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
	@property (readonly) BOOL isEmpty;

	- (instancetype _Nonnull)initWithIdentifier:(nonnull NSString *)identifier
								 cachedDelegate:(nonnull id <MADCacheProtocol>)cachedDelegate
										  types:(nonnull NSSet<Class> *)classes NS_DESIGNATED_INITIALIZER;
	- (instancetype _Nonnull)init NS_UNAVAILABLE;
	+ (instancetype _Nonnull)new NS_UNAVAILABLE;

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
