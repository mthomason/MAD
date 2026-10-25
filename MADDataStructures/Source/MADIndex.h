//
//  MADIndex.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDataStructures_MADIndex_h
#define MADDataStructures_MADIndex_h

#import <Foundation/NSObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADIndex : NSObject

@property (nonatomic, strong, readonly, nullable) id object;
@property (nonatomic, assign, readonly) NSUInteger index;

- (instancetype)initWithIndex:(NSUInteger)index
					andObject:(nullable id)object NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif
