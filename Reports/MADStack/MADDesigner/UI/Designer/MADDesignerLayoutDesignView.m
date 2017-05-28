//
//  MADDesignerLayoutDesignView.m
//  MAD Designer
//
//  Created by Michael on 5/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerLayoutDesignView.h"
#import "MADRulerView.h"
#import "NSLayoutConstraint+Designer.h"

const CGFloat MTReportDesignerBorderPaddingDetail        =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingVertical      =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingSides         =  8.0000f;


@interface MADDesignerLayoutDesignView ()

@property (readwrite, nonatomic, strong) NSArray <NSLayoutConstraint *> *rulerHorizontalConstraints;
@property (readwrite, nonatomic, strong) NSArray <NSLayoutConstraint *> *rulerVerticalConstraints;


/*    - (instancetype)initWithCoder:(NSCoder *)aDecoder;
    - (instancetype)initWithFrame:(CGRect)frame;
    - (void)setup;
    - (void)updateConstraints;
    - (void)removeFromSuperview;
    - (void)willMoveToSuperview:(UIView *)newSuperview;*/

@end

@implementation MADDesignerLayoutDesignView

- (void)dealloc {
    _rulerVerticalConstraints = nil;
    _rulerVerticalConstraints = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    MADRulerView *ruler = [[MADRulerView alloc] initWithFrame:CGRectZero];
    
    NSArray <NSLayoutConstraint *> *rulerVerticalConstraints, *rulerHorizontalConstraints;
    rulerVerticalConstraints = [MADLayoutConstraint constraintForRuler: ruler
                                                              designer: self
                                                             marginTop: MTReportDesignerBorderPaddingVertical
                                                                 heigh: MTReportDesignerRulerHeight
                                                           scaleFactor: 1.0];
    
    rulerHorizontalConstraints = [MADLayoutConstraint constraintForRuler: ruler
                                                                designer: self
                                                              sideMargin: MTReportDesignerBorderPaddingSides
                                                             scaleFactor: 1.0];
    
    NSArray <NSLayoutConstraint *> *allConstraints = [rulerVerticalConstraints arrayByAddingObjectsFromArray:rulerHorizontalConstraints];
    
    [self addSubview:ruler];
    [self addConstraints:allConstraints];
    
    self.rulerVerticalConstraints = rulerVerticalConstraints;
    self.rulerHorizontalConstraints = rulerHorizontalConstraints;
    
    self.ruler = ruler;
    
    allConstraints = nil;
    
}

- (void)updateConstraints {
    if (self.rulerVerticalConstraints == nil) {
    }
    [super updateConstraints];
}

/*- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self removeConstraints:self.rulerConstraints];
    self.rulerConstraints = nil;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview == nil) {
        [self removeConstraints:self.rulerConstraints];
        self.rulerConstraints = nil;
    }
}*/

- (void)setNeedsUpdateConstraints {
    [super setNeedsUpdateConstraints];
    [self.ruler setNeedsUpdateConstraints];
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self.ruler setNeedsLayout];
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [self.ruler setNeedsDisplay];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
