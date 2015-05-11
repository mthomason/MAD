//
//  MTViewPrintPageRenderReport.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportViewerReportPageView.h"

@interface MTReportViewerReportPageView ()

@end

@implementation MTReportViewerReportPageView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
}

- (void)drawRect:(CGRect)rect {
    if ([self drawBlankPage] == NO) {
        [self.delegate drawView:self inRect:rect];
    }
}

- (void)initalize {
    [self setDrawBlankPage:NO];
}

@end
