//
//  MTViewPrintPageRenderReport.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewPrintPageRenderReport.h"

@interface MTViewPrintPageRenderReport ()

@property (nonatomic, assign) NSUInteger pageNumber;
@property (nonatomic, retain) MTPrintPageRendererReport *printRenderData;

@end

@implementation MTViewPrintPageRenderReport

- (void)dealloc {
    [_printRenderData release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame pageNumber:(NSUInteger)pageNumber andPrintRenderData:(MTPrintPageRendererReport *)printRenderReport {
    self = [super initWithFrame:frame];
    if (self) {
        [self setPageNumber:pageNumber];
        [self setPrintRenderData:printRenderReport];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [[self printRenderData]  drawPageAtIndex: [self pageNumber] - 1
                                      inRect: rect];
}

@end