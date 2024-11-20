//
//  MADIndex.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2024 Michael Thomason. All rights reserved.
//

#ifndef MADDataStructures_MADIndex_h
#define MADDataStructures_MADIndex_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN // Assume non-null by default unless marked otherwise

/// Represents an immutable pairing of an object with an index.
@interface MADIndex : NSObject

/// The object associated with the index. Can be nil.
@property (nonatomic, strong, readonly, nullable) id object;

/// The associated index (non-negative integer).
@property (nonatomic, assign, readonly) NSUInteger index;

/// Initializes a MADIndex instance with an index and an object.
/// @param index The index value (must be non-negative).
/// @param object The associated object. Can be nil.
/// @return An initialized MADIndex instance.
- (instancetype)initWithIndex:(NSUInteger)index
					andObject:(nullable id)object NS_DESIGNATED_INITIALIZER;

/// Unavailable. Use `initWithIndex:andObject:` instead.
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif
