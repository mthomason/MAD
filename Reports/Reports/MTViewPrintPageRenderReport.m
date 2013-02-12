//
//  MTViewPrintPageRenderReport.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewPrintPageRenderReport.h"

@interface MTViewPrintPageRenderReport ()

@end

@implementation MTViewPrintPageRenderReport

- (void)dealloc {
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [[self delegate] drawView:self inRect:rect];
}

@end