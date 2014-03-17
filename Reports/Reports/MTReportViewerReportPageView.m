//
//  MTViewPrintPageRenderReport.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportViewerReportPageView.h"

@interface MTReportViewerReportPageView ()

@end

@implementation MTReportViewerReportPageView

- (id)init {
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    [self setDrawBlankPage:NO];
}

- (void)dealloc {
    _delegate = nil;
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    if ([self drawBlankPage] == NO) {
        [[self delegate] drawView:self inRect:rect];
    }
}

@end
