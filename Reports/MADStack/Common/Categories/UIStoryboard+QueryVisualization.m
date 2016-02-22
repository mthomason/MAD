//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+QueryVisualization.h"

static NSString * const QueryVisualization      = @"MADQueryVisualization";

@implementation UIStoryboard (QueryVisualization)

+ (instancetype)QueryVisualization {
    return [self storyboardWithName: QueryVisualization bundle: [NSBundle mainBundle]];
}

@end
