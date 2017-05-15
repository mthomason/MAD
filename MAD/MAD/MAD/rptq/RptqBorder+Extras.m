//
//  RptqBorder+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqBorder+Extras.h"

@implementation RptqBorder (Extras)

+ (NSString *)keyWidth {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(width));
    return key;
}

+ (NSString *)keyStyle {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(style));
    return key;
}

@end
