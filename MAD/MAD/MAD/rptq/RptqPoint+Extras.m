//
//  RptqPoint+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqPoint+Extras.h"

@implementation RptqPoint (Extras)

+ (NSString *)keyX {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(x));
    return key;
}

+ (NSString *)keyY {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(y));
    return key;
}

@end
