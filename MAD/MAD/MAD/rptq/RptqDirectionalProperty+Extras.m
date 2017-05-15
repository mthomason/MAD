//
//  RptqDirectionalProperty+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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

@end
