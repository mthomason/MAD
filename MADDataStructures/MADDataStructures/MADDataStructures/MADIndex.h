//
//  MADIndex.h
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDataStructures_MADIndex_h
#define MADDataStructures_MADIndex_h

#import <Foundation/NSObject.h>

@interface MADIndex : NSObject

    @property (nonatomic, strong, readonly) id object;
    @property (nonatomic, assign, readonly) NSUInteger index;

    - (instancetype)initWithIndex:(NSUInteger)index andObject:(id)object;

@end

#endif
