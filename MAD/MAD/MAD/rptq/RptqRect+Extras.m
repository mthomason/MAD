//
//  RptqRect+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqRect+Extras.h"

#import <CoreGraphics/CGGeometry.h>

#import "RptqPoint.h"
#import "RptqSize.h"

@implementation RptqRect (Extras)

+ (NSString *)keyOrigin {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(origin));
    return key;
}

+ (NSString *)keySize {
    static NSString *key = nil;
    if (key == nil) key = NSStringFromSelector(@selector(size));
    return key;
}

- (CGRect)frame {
    return CGRectMake(self.origin.x, self.origin.y, self.size.width, self.size.height);
}

@end
