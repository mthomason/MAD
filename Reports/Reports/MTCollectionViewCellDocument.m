//
//  MTCollectionViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewCellDocument.h"

@implementation MTCollectionViewCellDocument

- (void)dealloc {
    [_labelTitle release];
    [_imagePreview release];
    [super dealloc];
}

- (void)awakeFromNib {
    
    UIView *selectedBackground = [[UIView alloc] initWithFrame:[self frame]];
    [[selectedBackground layer] setCornerRadius: 5.0000f];
    [selectedBackground setClipsToBounds:YES];

    [selectedBackground setBackgroundColor:[UIColor edaBlueDarkSelection]];
    [self setSelectedBackgroundView:selectedBackground];
    [selectedBackground release];
    
    [super awakeFromNib];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
