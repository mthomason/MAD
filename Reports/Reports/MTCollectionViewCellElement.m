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

@end