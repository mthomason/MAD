//
//  MADVectorBool.m
//  MADDataStructures
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADVectorBool.h"
#import <Foundation/NSString.h>

#include <vector>
#include <iostream>
#include <iterator>

struct MADVectorBoolImpl;

@interface MADVectorBool () {
    struct MADVectorBoolImpl *impl;
  }

@end

/*
 // Example cpp class include
 namespace MADContainers {
    class VectorBool {
        
    public:
        std::vector<bool> container;

        void push_true() { this->container.push_back(true); };
        void push_false() { this->container.push_back(false); };
        void clear() { this->container.clear(); }
        unsigned long count() { return this->container.size(); }

    };
};

 */

struct MADVectorBoolImpl {
    std::vector<bool> _container;
};

@implementation MADVectorBool

- (void)dealloc {
    impl->_container.clear();
    delete impl;
}

- (instancetype)init {
    if (self = [super init]) {
        impl = new MADVectorBoolImpl;
    }
    return self;
}

- (void)push:(BOOL)value {
    if (value) impl->_container.push_back(true);
    else impl->_container.push_back(false);
}

- (void)addTrue {
    impl->_container.push_back(true);
}
- (void)addFalse {
    impl->_container.push_back(false);
}

- (unsigned long)count {
    return impl->_container.size();
}

- (void)enumerateBools:(void (^)(NSUInteger idx, BOOL valid, BOOL *stop))valueHandler {
    BOOL stop = NO;
    NSUInteger counter = 0;
    for (auto i = impl->_container.begin(); i != impl->_container.end(); ++i) {
        valueHandler(counter, *i ? YES : NO, &stop);
        if (stop) break;
        ++counter;
    }
}

- (id)debugQuickLookObject {
    NSMutableString *debuggingString = [[NSMutableString alloc] init];
    for (auto i = impl->_container.begin(); i != impl->_container.end(); ++i) {
        [debuggingString appendFormat:@"%@\n", (*i ? @"YES" : @"NO")];
    }
    return debuggingString;
}

@end
