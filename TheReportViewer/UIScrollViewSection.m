//
//  UIScrollViewDashboard.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIScrollViewSection.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIScrollViewSection
@synthesize objectID = _objectID;
@synthesize localizedName = _localizedName;
@synthesize highlighted = _highlighted;

- (void)dealloc {
    [_objectID release];
    [_localizedName release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    
    //if ([self localizedName]) {
        if (![self isHighlighted]) {
            //[[UIColor blackColor] setStroke];
            //[[UIColor blackColor] set];
        } else {
            //[[UIColor redColor] setStroke];
            //[[UIColor redColor] set];
        }
        [[self localizedName] drawInRect: rect
                      withFont: [UIFont systemFontOfSize:([UIFont systemFontSize])]
                 lineBreakMode: UILineBreakModeClip
                     alignment: UITextAlignmentLeft];
    //}
    
}

@end