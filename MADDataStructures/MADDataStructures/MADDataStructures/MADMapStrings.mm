//
//  MADMapStrings.m
//  MADDataStructures
//
//  Created by Michael on 1/1/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADMapStrings.h"

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

#include <cstddef>
#include <string>
#include <map>

template<typename T>
struct MADMapStringsImpl;

template<typename T>
struct MADMapStringsImpl {
	std::map<T, std::string> _container;
};

template<typename Type>
class MADMad {
	
	std::map<Type, std::string> _container;
  public:
	std::string::size_type count() {
		return this->_container.size();
	}
	void setObject(NSString *obj, Type key) {
		if (obj != nil) {
			std::string cpp_str([obj UTF8String], [obj lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
			_container[key] = cpp_str;
		} else {
			_container.erase(key);
		}
	}
	NSString *objectAtIndex(Type index) {
		typename std::map<Type, std::string>::const_iterator found = _container.find(index);
		if (found == _container.end()) return nil;
		NSString *result = [[NSString alloc] initWithBytes:found->second.data()
													length:found->second.size()
												  encoding:NSUTF8StringEncoding];
		return result;
	}
};

@implementation MADMapStrings

- (instancetype)initWithType:(MADMapDataType)t {
	typeof(self) map;
	switch (t) {
	
		case MADMapDataTypeShort:
			map = [[MADMapStringsShort alloc] init];
			break;
		case MADMapDataTypeInteger:
			map = [[MADMapStringsInteger alloc] init];
			break;
		case MADMapDataTypeUnsignedInteger:
			map = [[MADMapStringsUnsignedInteger alloc] init];
			break;
			
		default:
			NSAssert(NO, @"Invalid MADMapDataType");
			map = nil;
			break;
	}
	return map;
}

- (unsigned long)count {
	return 0;
}

@end

@implementation MADMapStringsInteger {
	MADMad<NSInteger> *impl;
}

- (instancetype)init {
	if (self = [super init]) {
		impl = new MADMad<NSInteger>();
	}
	return self;
}

- (NSString *)objectAtIndex:(NSInteger)i {
	return impl->objectAtIndex(i);
}

- (void)setObject:(NSString *)str toKey:(NSInteger)key {
	impl->setObject(str, key);
}

- (unsigned long)count {
	return impl->count();
}

- (void)dealloc {
	delete impl;
}

@end

@implementation MADMapStringsShort {
	struct MADMapStringsImpl <short> *impl;
}

- (void)dealloc {
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
		//cpp_str.erase();
		
	} else {
		impl->_container.erase(key);
		
	}
}

- (unsigned long)count {
	return impl->_container.size();
}

@end

@implementation MADMapStringsUnsignedInteger {
	struct MADMapStringsImpl <NSUInteger> *impl;
}

- (void)dealloc {
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
		//cpp_str.erase();
		
	} else {
		impl->_container.erase(key);
		
	}
}

- (unsigned long)count {
	return impl->_container.size();
}

@end
