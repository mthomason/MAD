//
//  MADMapStrings.m
//  MADDataStructures
//
//  Created by Michael on 1/1/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADMapStrings.h"

#import <Foundation/NSString.h>

#include <cstddef>
#include <string>
#include <map>

struct MADMapStringsImpl;

@interface MADMapStrings () {
    struct MADMapStringsImpl *impl;
}

@end

struct MADMapStringsImpl {
    std::map<short, std::string> _container;
};

@implementation MADMapStrings

- (void)dealloc {
    impl->_container.clear();
    delete impl;
}

- (instancetype)init {
    if (self = [super init]) {
        impl = new MADMapStringsImpl;
    }
    return self;
}

- (unsigned long)count {
    return impl->_container.size();
}

- (NSString *)objectAtIndex:(short)i {

    std::map<short, std::string>::const_iterator found = impl->_container.find(i);
    if (found == impl->_container.end()) return nil;
    
    const char *c_str = found->second.c_str();
    NSString *result = [NSString stringWithCString:c_str encoding:NSUTF8StringEncoding];
    return result;
}

- (void)setObject:(NSString *)str toKey:(short)key {

    if (str != nil) {
        std::string cpp_str([str UTF8String], [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        impl->_container[key] = cpp_str;
        
    } else {
        impl->_container.erase(key);
        
    }
}

@end
