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

template<typename T>
struct MADMapStringsImpl;

template<typename T>
struct MADMapStringsImpl {
    std::map<T, std::string> _container;
};

@implementation MADMapStrings

- (instancetype)initWithType:(MADDataType)t {
    id map;
    switch (t) {
    
        case MADDataTypeShort:
            map = [[MADMapStringsShort alloc] init];
            break;
        case MADDataTypeInteger:
            map = [[MADMapStringsInteger alloc] init];
            break;
        case MADDataTypeUnsignedInteger:
            map = [[MADMapStringsUnsignedInteger alloc] init];
            break;
            
        default:
            break;
    }
    return map;
}

- (unsigned long)count {
    return 0;
}

@end

@implementation MADMapStringsInteger {
    struct MADMapStringsImpl <NSInteger> *impl;
}

- (instancetype)init {
    if (self = [super init]) {
        impl = new MADMapStringsImpl<NSInteger>;
    }
    return self;
}

- (NSString *)objectAtIndex:(NSInteger)i {
    
    std::map<NSInteger, std::string>::const_iterator found = impl->_container.find(i);
    if (found == impl->_container.end()) return nil;
    
    const char *c_str = found->second.c_str();
    NSString *result = [[NSString alloc] initWithCString:c_str encoding:NSUTF8StringEncoding];
    return result;
}

- (void)setObject:(NSString *)str toKey:(NSInteger)key {
    
    if (str != nil) {
        std::string cpp_str([str UTF8String], [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        impl->_container[key] = cpp_str;
        
    } else {
        impl->_container.erase(key);
        
    }
}

- (unsigned long)count {
    return impl->_container.size();
}

@end

@implementation MADMapStringsShort {
    struct MADMapStringsImpl <short> *impl;
}

- (void)dealloc {
    impl->_container.clear();
    delete impl;
}

- (instancetype)init {
    if (self = [super init]) {
        impl = new MADMapStringsImpl<short>;
    }
    return self;
}

- (NSString *)objectAtIndex:(short)i {
    
    std::map<short, std::string>::const_iterator found = impl->_container.find(i);
    if (found == impl->_container.end()) return nil;
    
    const char *c_str = found->second.c_str();
    NSString *result = [[NSString alloc] initWithCString:c_str encoding:NSUTF8StringEncoding];
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

@implementation MADMapStringsUnsignedInteger {
    struct MADMapStringsImpl <NSUInteger> *impl;
}

- (void)dealloc {
    impl->_container.clear();
    delete impl;
}

- (instancetype)init {
    if (self = [super init]) {
        impl = new MADMapStringsImpl<NSUInteger>;
    }
    return self;
}

- (NSString *)objectAtIndex:(NSUInteger)i {
    
    std::map<NSUInteger, std::string>::const_iterator found = impl->_container.find(i);
    if (found == impl->_container.end()) return nil;
    
    const char *c_str = found->second.c_str();
    NSString *result = [[NSString alloc] initWithCString:c_str encoding:NSUTF8StringEncoding];
    return result;
}

- (void)setObject:(NSString *)str toKey:(NSUInteger)key {
    
    if (str != nil) {
        std::string cpp_str([str UTF8String], [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        impl->_container[key] = cpp_str;
        
    } else {
        impl->_container.erase(key);
        
    }
}

- (unsigned long)count {
    return impl->_container.size();
}

@end


