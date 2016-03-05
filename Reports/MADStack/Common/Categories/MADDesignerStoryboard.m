//
//  MADDesignerStoryboard.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerStoryboard.h"

static NSString * const StoryboardDesigner     = @"MADDesigner";

@implementation MADDesignerStoryboard

+ (instancetype)DesignerStoryboard {
    id designer = [self storyboardWithName: StoryboardDesigner bundle: NULL];
    return designer;
}

@end
