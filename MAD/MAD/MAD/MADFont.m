//
//  MTFont.m
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADFont.h"

static NSString * const MTFontFamilyHelveticaNeue = @"Helvetica Neue";

@implementation MADFont

    + (NSString *)defaultFamily { return MTFontFamilyHelveticaNeue; }
    + (float)defaultSize { return 9.0; }

@end
