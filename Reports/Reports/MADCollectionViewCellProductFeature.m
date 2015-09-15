//
//  MADCollectionViewCellProductFeature.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCollectionViewCellProductFeature.h"
#import "MADBackgroundView.h"
#import "UIColor+EverydayApps.h"

@interface MADCollectionViewCellProductFeature ()

@property (nonatomic, strong) UIColor *textColorFromNib;

@end

@implementation MADCollectionViewCellProductFeature

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        UIView *selectedBackgroundView = [[MADBackgroundViewSelected alloc] initWithFrame:self.bounds];
        UIView *backgroundView = [[MADBackgroundView alloc] initWithFrame:self.bounds];
        
        self.selectedBackgroundView = selectedBackgroundView;
        self.backgroundView = backgroundView;
        
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    CGRect r = CGRectMake(CGPointZero.x, CGPointZero.y,
               self.image.bounds.size.width + 4.0000f, self.image.bounds.size.height + 4.0000f);
    UIBezierPath *exclusionPath = [UIBezierPath bezierPathWithRect:r];
    self.labelDescription.textContainer.exclusionPaths = @[exclusionPath];
    self.textColorFromNib = self.labelDescription.textColor;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.labelDescription.textColor = highlighted || self.selected ? self.labelTitle.highlightedTextColor : self.textColorFromNib;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.labelDescription.textColor = selected || self.highlighted ? self.labelTitle.highlightedTextColor : self.textColorFromNib;
}

@end
