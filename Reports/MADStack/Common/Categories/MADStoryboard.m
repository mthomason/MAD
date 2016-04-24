//
//  MADDesignerStoryboard.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADStoryboard.h"

static NSString * const StoryboardDesigner     = @"MADDesigner";

@implementation MADStoryboard

+ (instancetype)newStoryboardDesigner {
    id designer = [self storyboardWithName: StoryboardDesigner bundle: NULL];
    return designer;
}

@end
