//
//  MADStandard.m
//  MADExplorer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADStandard.h"
#import <Foundation/NSString.h>
#include <string>
#include <cmath>

@implementation MADStandard

+ (instancetype)newStandardStringForDouble:(double)d {
    std::string d_str = std::to_string(d);
    const char *c_str = d_str.c_str();
    id result = [[NSString alloc] initWithUTF8String: c_str];
    return result;
}

+ (instancetype)newStandardStringForUnsignedLong:(unsigned long)ul {
    std::string d_str = std::to_string(ul);
    const char *c_str = d_str.c_str();
    id result = [[NSString alloc] initWithUTF8String: c_str];
    return result;
}

+ (instancetype)newStandardStringForFileSize:(unsigned long long)filesize {
    const std::string decimal = ".", zero = "0", mb = " MB";
    const double roundFactor = 1000.0, bitsToMBFactor = 1000000.0;
    std::string filesize_str;
    filesize_str = std::to_string((round((filesize / bitsToMBFactor) * roundFactor) / roundFactor));
    
    size_t dec_locatoin = filesize_str.find_first_of(decimal);
    size_t range_end = dec_locatoin + 4;
    if (filesize_str.length() <= range_end) {
        filesize_str.append(zero, range_end);
    }
    std::string substring = filesize_str.substr(0, range_end);
    substring.append(mb);
    const char *c_str = substring.c_str();
    id result = [[NSString alloc] initWithUTF8String: c_str];
    return result;
}

@end
