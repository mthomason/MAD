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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

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

- (NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *)sectionViews {
    return self.scroller.sectionViews;
}

- (NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *)sectionLabels {
    return self.scroller.sectionLabels;
}

@end
