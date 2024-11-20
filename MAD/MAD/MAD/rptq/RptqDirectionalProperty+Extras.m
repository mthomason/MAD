//
//  RptqDirectionalProperty+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDirectionalProperty+Extras.h"

@implementation RptqDirectionalProperty (Extras)

+ (NSString *)keyTop {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(top));
    return key;
}

+ (NSString *)keyBottom {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(bottom));
    return key;
}

+ (NSString *)keyLeft {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(left));
    return key;
}

+ (NSString *)keyRight {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(right));
    return key;
}

@end
