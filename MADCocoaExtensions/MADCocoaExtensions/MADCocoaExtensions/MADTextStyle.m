//
//  MADTextStyle.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTextStyle.h"
#import <Foundation/NSCoder.h>
#import <string.h>

@implementation MADTextStyle {
    MADTextStyle_t _style;
}

@dynamic bold;
@dynamic italic;
@dynamic underline;
@dynamic strikethrough;

- (instancetype)initWithBold:(BOOL)bold italic:(BOOL)italic
                   underline:(BOOL)underline strikethrough:(BOOL)strikethrough {
    if (self = [super init]) {
        _style = MADLayoutTextStyleMake(bold, strikethrough, italic, underline);

    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSUInteger lenght;
        memcpy(&_style,
               [aDecoder decodeBytesForKey:@"s" returnedLength:&lenght],
               sizeof(MADTextStyle_t));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBytes:(uint8_t *)&_style length:sizeof(MADTextStyle_t) forKey:@"s"];
}

- (BOOL)bold {
    return _style.bold;
}

- (BOOL)italic {
    return _style.italic;
}

- (BOOL)underline {
    return _style.underline;
}

- (BOOL)strikethrough {
    return _style.strikethrough;
}

@end
