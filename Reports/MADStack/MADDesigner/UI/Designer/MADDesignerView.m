//
//  MADDesignerView.m
//  MAD Designer
//
//  Created by Michael on 5/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerView.h"
#import "MADDesignerScrollView.h"
#import "MADDesignerLayoutDesignView.h"

@implementation MADDesignerView

- (void)setNeedsUpdateConstraints {
    [super setNeedsUpdateConstraints];
    [self.scroller setNeedsUpdateConstraints];
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self.scroller setNeedsLayout];
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [self.scroller setNeedsDisplay];
}

- (CGSize)contentViewSize {
    return CGSizeMake(self.bounds.size.width, self.scroller.container.sizeHeight);
}

@end
