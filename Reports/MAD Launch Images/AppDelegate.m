//
//  AppDelegate.m
//  MAD Launch Images
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

+ (BOOL)isMadDesigner {
    return NO;
}

@end
