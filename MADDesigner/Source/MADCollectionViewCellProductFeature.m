//
//  MADCollectionViewCellProductFeature.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADCollectionViewCellProductFeature.h"
#import <MADExplorer/MADBackgroundViewSelected.h>
#import <UIKit/UIView.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UIBezierPath.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UITextView.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSTextContainer.h>

static inline CGRect ImageSize(CGSize size) {
    return CGRectMake(CGPointZero.x, CGPointZero.y, size.width + 4.0, size.height + 4.0);
}

@interface MADCollectionViewCellProductFeature ()

    @property (nonatomic, copy) UIColor *textColorFromNib;

@end

@implementation MADCollectionViewCellProductFeature

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		UIView *selectedBackgroundView = [[MADBackgroundViewSelected alloc] initWithFrame:self.bounds];
		UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: 1.0/3.0];
		backgroundView.clipsToBounds = YES;
		backgroundView.layer.cornerRadius = 5.0;
		self.selectedBackgroundView = selectedBackgroundView;
		self.backgroundView = backgroundView;
	}
	return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    id exclusionPath = [UIBezierPath bezierPathWithRect: ImageSize(self.image.bounds.size)];
    id exclusionPaths = [[NSArray alloc] initWithObjects:exclusionPath, nil];
    self.labelDescription.textContainer.exclusionPaths = exclusionPaths;
    self.textColorFromNib = self.labelDescription.textColor.copy;
}

- (void)setHighlighted:(BOOL)highlighted {
    super.highlighted = highlighted;
    self.labelDescription.textColor = highlighted || self.selected ?
                                self.labelTitle.highlightedTextColor.copy :
                                self.textColorFromNib.copy;
}

- (void)setSelected:(BOOL)selected {
    super.selected = selected;
    self.labelDescription.textColor = selected || self.highlighted ?
                                    self.labelTitle.highlightedTextColor.copy :
                                    self.textColorFromNib.copy;
}

@end
