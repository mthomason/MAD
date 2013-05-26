//
//  MTCollectionViewCell.m
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewCellElement.h"

@implementation MTCollectionViewCellElement

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //[self setUserInteractionEnabled:YES];
        // Initialization code
    }
    return self;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    for (UIView *subview in [[self contentView] subviews]) {
        [subview setNeedsDisplay];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(delete:)) {
        result = YES;
    }
    return result;
}

- (void)delete:(id)sender {
    [[self delegate] deleteDocumentObjectRepresentedByCell:self];
}

@end
