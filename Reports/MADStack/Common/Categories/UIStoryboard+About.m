//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+About.h"

static NSString * const About                   = @"MADStoryboardAbout";

@implementation UIStoryboard (About)

+ (instancetype)About {
    return [self storyboardWithName: About bundle:nil];
}

@end
