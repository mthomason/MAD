//
//  MADDesignerStoryboard.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADStoryboard.h"

static NSString * const StoryboardDesigner      = @"MADDesigner";
static NSString * const Query                   = @"MADQuery";
static NSString * const Toolbox                 = @"MADToolbox";
static NSString * const Licensing               = @"MADLicensing";
static NSString * const ObjectSelector          = @"MADStoryboardObjectSelector";

@implementation MADStoryboard

+ (instancetype)newStoryboardDesigner {
    id designer = [self storyboardWithName: StoryboardDesigner bundle: NULL];
    return designer;
}

+ (instancetype)newStoryboardQuery {
    id bundle =         [NSBundle mainBundle];
    id storybard =      [self storyboardWithName: Query bundle: bundle];
    return storybard;
}

+ (instancetype)newToolbox {
    id bundle =         [NSBundle mainBundle];
    id storyboard =     [self storyboardWithName: Toolbox bundle: bundle];
    return storyboard;
}

+ (instancetype)newLicensing {
    id bundle =         [NSBundle mainBundle];
    id storyboard =     [self storyboardWithName: Licensing bundle:bundle];
    return storyboard;
}

+ (instancetype)ObjectSelector {
    id bundle =         [NSBundle mainBundle];
    id storyboard =     [self storyboardWithName: ObjectSelector bundle: bundle];
    return storyboard;
}

@end
