//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADToolboxStoryboard.h"

static NSString * const Toolbox = @"MADToolbox";

@implementation MADToolboxStoryboard

+ (instancetype)ToolboxStoryboard {
    id sb = [self storyboardWithName: Toolbox bundle: NULL];
    return sb;
}

@end
