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
    
    [[self imagePreview] setContentMode:UIViewContentModeScaleAspectFit];
    
    [super awakeFromNib];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(email:) || action == @selector(delete:)) {
        result = YES;
    }
    return result;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)delete:(id)sender {
    [[self delegate] deleteDocumentRepresentedByCell:self];
}

- (void)email:(id)sender {
    [[self delegate] emailDocumentRepresentedByCell:self];
}

@end
