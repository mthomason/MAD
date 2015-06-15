//
//  UIStoryboard+Viewer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+Viewer.h"

NSString * const MADHandleStoryboardViewer  = @"MADViewer";

@implementation UIStoryboard (Viewer)

+ (UIStoryboard *)viewer {
    return [UIStoryboard storyboardWithName:MADHandleStoryboardViewer bundle:nil];
}

@end
