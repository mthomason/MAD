//
//  MTScrollViewCenter.m
//  Reports
//
//  Created by Michael Thomason on 2/21/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTScrollViewCenter.h"

@implementation MTScrollViewCenter

- (void)setContentOffset:(CGPoint)point {
    id retainedDelegate = [[self delegate] retain];
    if (retainedDelegate) {
        UIView *contentView = [[retainedDelegate viewForZoomingInScrollView:self] retain];
        if (contentView) {
            CGSize viewSize = [contentView frame].size;
            CGSize scrollSize = [self bounds].size;
            
            if(viewSize.width < scrollSize.width) {
                point.x = -(scrollSize.width - viewSize.width) / 2.0000f;
            }

            if(viewSize.height < scrollSize.height) {
                point.y = -(scrollSize.height - viewSize.height) / 2.0000f;
            }
        }
        [contentView release];
    }
    [retainedDelegate release];
    [super setContentOffset: point];
}

@end
