//
//  MADMargin.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADMargin.h"
#import <Foundation/NSCoder.h>
#import <string.h>

@implementation MADMargin {
    MADMargin_t _margin;
}

@dynamic left;
@dynamic right;
@dynamic top;
@dynamic bottom;

+ (BOOL)supportsSecureCoding {
    return NO;
}

- (instancetype)initWithLeft:(Float64)left right:(Float64)right
                         top:(Float64)top bottom:(Float64)bottom {
    if (self = [super init]) {
        _margin = MADLayoutMarginMake(left, right, top, bottom);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSUInteger lenght;
        memcpy(&_margin,
               [aDecoder decodeBytesForKey:@"m" returnedLength:&lenght],
               sizeof(MADMargin_t));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBytes:(uint8_t *)&_margin length:sizeof(MADMargin_t) forKey:@"m"];
}

- (Float64)left {
    return _margin.left;
}

- (Float64)right {
    return _margin.right;
}

- (Float64)top {
    return _margin.top;
}

- (Float64)bottom {
    return _margin.bottom;
}

@end
