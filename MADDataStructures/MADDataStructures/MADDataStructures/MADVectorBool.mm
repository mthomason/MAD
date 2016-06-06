//
//  MADVectorBool.m
//  MADDataStructures
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADVectorBool.h"
#include <vector>
#include <iostream>
#include <iterator>

@interface MADVectorBool () {
    std::vector<bool> _container;
}

@end

@implementation MADVectorBool

- (void)dealloc {
    self->_container.clear();
}

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)addTrue {
    self->_container.push_back(true);
}
- (void)addFalse {
    self->_container.push_back(false);
}

- (unsigned long)count {
    return self->_container.size();
}

- (void)enumerateBools:(void (^)(NSUInteger idx, BOOL valid, BOOL *stop))valueHandler {
    BOOL stop = NO;
    NSUInteger counter = 0;
    for (auto i = _container.begin(); i != _container.end(); ++i) {
        valueHandler(counter, *i ? YES : NO, &stop);
        if (stop) break;
        ++counter;
    }
}

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [[NSMutableString alloc] init];
    for (auto i = _container.begin(); i != _container.end(); ++i) {
        [debuggingString appendFormat:@"%@\n", (*i ? @"YES" : @"NO")];
    }
    return debuggingString;
}

@end
