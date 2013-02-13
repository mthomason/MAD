//
//  MTCollectionViewSection.m
//  Reports
//
//  Created by Michael Thomason on 12/26/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewSection.h"

@implementation MTCollectionViewSection

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return @selector(cut:) || @selector(copy:) || @selector(paste:) || @selector(delete:) ||
            @selector(select:) || @selector(selectAll:) || @selector(toggleBoldface:) ||
            @selector(toggleItalics:) || @selector(toggleUnderline:) ||
            [super canPerformAction:action withSender:sender];
}

@end