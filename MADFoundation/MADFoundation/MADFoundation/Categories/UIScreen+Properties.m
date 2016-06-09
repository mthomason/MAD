//
//  UIScreen+Properties.m
//  MADFoundation
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "UIScreen+Properties.h"

@implementation UIScreen (Properties)

- (BOOL)isRetnaDisplay {
    return [UIScreen mainScreen].scale > 1.5;
}

@end
