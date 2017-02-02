//
//  MADAlignment.m
//  MAD
//
//  Created by Michael on 2/2/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADAlignment.h"
#import <Foundation/NSCoder.h>
#import <string.h>

@implementation MADAlignment {
    MADAlignment_t _alignment;
}

@dynamic horizontal;
@dynamic vertical;

- (instancetype)initWithHorizontal:(MADHorizontalAlignment)horizontal
                          vertical:(MADVerticalAlignment)vertical {
    if (self = [super init]) {
        _alignment = MADAlignmentMake(horizontal, vertical);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSUInteger lenght;
        memcpy(&_alignment,
               [aDecoder decodeBytesForKey:@"a" returnedLength:&lenght],
               sizeof(MADAlignment_t));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBytes:(uint8_t *)&_alignment length:sizeof(MADAlignment_t) forKey:@"a"];
}

- (MADHorizontalAlignment)horizontal {
    return _alignment.horizontal;
}

- (MADVerticalAlignment)vertical {
    return _alignment.vertical;
}

@end
