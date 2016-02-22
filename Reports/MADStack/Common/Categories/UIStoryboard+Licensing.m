//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+Licensing.h"

static NSString * const Licensing               = @"MADLicensing";

@implementation UIStoryboard (Licensing)

+ (instancetype)Licensing {
    return [self storyboardWithName: Licensing bundle:nil];
}

@end
