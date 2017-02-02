//
//  MADPadding.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPadding.h"
#import <Foundation/NSCoder.h>
#import <string.h>

@implementation MADPadding {
    MADLayoutPadding_t _padding;
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
        _padding = MADLayoutPaddingMake(left, right, top, bottom);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSUInteger lenght;
        memcpy(&_padding,
               [aDecoder decodeBytesForKey:@"p" returnedLength:&lenght],
               sizeof(MADLayoutPadding_t));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBytes:(uint8_t *)&_padding length:sizeof(MADLayoutPadding_t) forKey:@"p"];
}

- (Float64)left {
    return _padding.left;
}

- (Float64)right {
    return _padding.right;
}

- (Float64)top {
    return _padding.top;
}

- (Float64)bottom {
    return _padding.bottom;
}

@end
