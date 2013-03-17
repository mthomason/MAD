//
//  MTViewPrintPageRenderReport.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerReportPageView.h"

@interface MTReportViewerReportPageView ()

@end

@implementation MTReportViewerReportPageView

- (void)dealloc {
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //NSLog(@"Bounds %@", NSStringFromCGRect(self.bounds));
    //[[[self delegate] delegate] reloadReportView];
    //[[[[self delegate] delegate] printPageRendererReport] setPrintableSize:[self bounds].size];
    //[[[[self delegate] delegate] printPageRendererReport] cachePrintPageRenderData];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [[self delegate] drawView:self inRect:rect];
}

@end