//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+Designer.h"

static NSString * const Toolbox                 = @"MADToolbox";

@implementation UIStoryboard (Toolbox)

+ (instancetype)Toolbox {
    return [self storyboardWithName: Toolbox bundle: [NSBundle mainBundle]];
}

@end
