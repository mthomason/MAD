//
//  UIScrollViewDashboard.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIScrollViewSection.h"

@implementation UIScrollViewSection
@synthesize objectID = _objectID;

- (void)dealloc {
    [_objectID release];
    [super dealloc];
}

@end