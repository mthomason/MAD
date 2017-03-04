//
//  MADIndex.m
//  MADDataStructures
//
//  Created by Michael Thomason on 3/12/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADIndex.h"

@interface MADIndex ()

    @property (nonatomic, strong, readwrite) id object;
    @property (nonatomic, assign, readwrite) NSUInteger index;

@end

@implementation MADIndex

- (instancetype)initWithIndex:(NSUInteger)index andObject:(id)object {
    if (self = [super init]) {
        
        _index = index;

        id __strong obj = object;
        _object = obj;
    }
    return self;
}

@end
