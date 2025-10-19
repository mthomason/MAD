//
//  MADVibrantTableViewCellImage.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADVibrantTableViewCellImage.h"

#import <UIKit/UINibLoading.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>

static inline CGFloat lclbConstant(MADVibrantTableViewCellMarginStyle);
static inline NSLayoutAttribute lclbAttribute1(MADVibrantTableViewCellMarginStyle);

static inline CGFloat lclbConstant(MADVibrantTableViewCellMarginStyle marginStyle) {
	return marginStyle == MADTableViewCellMarginStyleBottom || marginStyle == MADTableViewCellMarginStyleFat || marginStyle == MADTableViewCellMarginStyleMiddle ? -4.0 : 0.0;
}

static inline NSLayoutAttribute lclbAttribute1(MADVibrantTableViewCellMarginStyle marginStyle) {
	return marginStyle == MADTableViewCellMarginStyleBottom || marginStyle == MADTableViewCellMarginStyleFat || marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeBottomMargin : NSLayoutAttributeBottom;
}

@interface MADVibrantTableViewCellImage ()

@property (atomic, assign) BOOL initalSetupImageComplete;

@end

@implementation MADVibrantTableViewCellImage

- (void)awakeFromNib {
	[self initialize];
	[self layoutIfNeeded];
	[super awakeFromNib];
}

- (void)initialize {
	self.updatingConstraints = NO;
	self.initalSetupImageComplete = NO;
	[super initialize];
}

- (void)invalidateConstraints {
	UIVisualEffectView *effectView = self.effectView;
	UILabel *label = self.label;
	if (self.updatingConstraints == NO && self.initalSetupImageComplete &&
		effectView != nil && label != nil && self.imageViewMain != nil) {
		self.updatingConstraints = YES;
		
		if (self.layoutConstraints.count > 0) {
			[self.contentView removeConstraints:self.layoutConstraints];
		}
		
		NSLayoutConstraint *ch = [NSLayoutConstraint constraintWithItem: self.contentView
															  attribute: NSLayoutAttributeHeight
															  relatedBy: NSLayoutRelationGreaterThanOrEqual
																 toItem: effectView.contentView
															  attribute: NSLayoutAttributeHeight
															 multiplier: 1.0
															   constant: 0.0];
		
		NSLayoutConstraint *eh = [NSLayoutConstraint constraintWithItem: effectView.contentView
															  attribute: NSLayoutAttributeHeight
															  relatedBy: NSLayoutRelationGreaterThanOrEqual
																 toItem: label
															  attribute: NSLayoutAttributeHeight
															 multiplier: 1.0
															   constant: 0.0];

		NSLayoutConstraint *ih = [NSLayoutConstraint constraintWithItem: self.contentView
															  attribute: NSLayoutAttributeHeight
															  relatedBy: NSLayoutRelationGreaterThanOrEqual
																 toItem: self.imageViewMain
															  attribute: NSLayoutAttributeHeight
															 multiplier: 1.0
															   constant: 2.0 * 4.0];

		NSLayoutConstraint *isw = [NSLayoutConstraint constraintWithItem: self.imageViewMain
															   attribute: NSLayoutAttributeWidth
															   relatedBy: NSLayoutRelationEqual
																  toItem: nil
															   attribute: NSLayoutAttributeNotAnAttribute
															  multiplier: 1.0
																constant: self.imageViewMain.image.size.width];

		NSLayoutConstraint *ish = [NSLayoutConstraint constraintWithItem: self.imageViewMain
															   attribute: NSLayoutAttributeHeight
															   relatedBy: NSLayoutRelationEqual
																  toItem: nil
															   attribute: NSLayoutAttributeNotAnAttribute
															  multiplier: 1.0
																constant: self.imageViewMain.image.size.height];

		NSLayoutConstraint *lcli = [NSLayoutConstraint constraintWithItem: self.contentView
																attribute: NSLayoutAttributeLeading
																relatedBy: NSLayoutRelationEqual
																   toItem: self.imageViewMain
																attribute: NSLayoutAttributeLeading
															   multiplier: 1.0
																 constant: -4.0];
		lcli.priority = UILayoutPriorityRequired;

		NSLayoutConstraint *lcmil = [NSLayoutConstraint constraintWithItem: self.imageViewMain
																 attribute: NSLayoutAttributeTrailing
																 relatedBy: NSLayoutRelationEqual
																	toItem: effectView.contentView
																 attribute: NSLayoutAttributeLeading
																multiplier: 1.0
																  constant: 0.0];
		lcmil.priority = UILayoutPriorityRequired;

		
		NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem: self.contentView
															   attribute: NSLayoutAttributeTrailing
															   relatedBy: NSLayoutRelationEqual
																  toItem: effectView.contentView
															   attribute: NSLayoutAttributeTrailing
															  multiplier: 1.0
																constant: 0.0];
		lc2.priority = UILayoutPriorityRequired;
		
		NSLayoutConstraint *lc4 = [NSLayoutConstraint constraintWithItem: self.contentView
															   attribute: NSLayoutAttributeTop
															   relatedBy: NSLayoutRelationEqual
																  toItem: effectView.contentView
															   attribute: NSLayoutAttributeTop
															  multiplier: 1.0
																constant: 0.0];
		lc4.priority = UILayoutPriorityRequired;

		NSLayoutConstraint *lc6 = [NSLayoutConstraint constraintWithItem: self.contentView
															   attribute: NSLayoutAttributeBottom
															   relatedBy: NSLayoutRelationEqual
																  toItem: effectView.contentView
															   attribute: NSLayoutAttributeBottom
															  multiplier: 1.0
																constant: 0.0];
		lc6.priority = UILayoutPriorityRequired;

		NSLayoutConstraint *lcicy = [NSLayoutConstraint constraintWithItem: self.imageViewMain
																 attribute: NSLayoutAttributeCenterY
																 relatedBy: NSLayoutRelationEqual
																	toItem: self.contentView
																 attribute: NSLayoutAttributeCenterY
																multiplier: 1.0
																  constant: 0.0];

		NSLayoutConstraint *lcllm = [NSLayoutConstraint constraintWithItem: effectView.contentView
																 attribute: NSLayoutAttributeLeadingMargin
																 relatedBy: NSLayoutRelationEqual
																	toItem: label
																 attribute: NSLayoutAttributeLeading
																multiplier: 1.0
																  constant: 0.0];
		lcllm.priority = UILayoutPriorityRequired;
		
		NSLayoutConstraint *lcla = [NSLayoutConstraint constraintWithItem: effectView.contentView
																attribute: NSLayoutAttributeTrailing
																relatedBy: NSLayoutRelationEqual
																   toItem: label
																attribute: NSLayoutAttributeTrailing
															   multiplier: 1.0
																 constant: 4.0];
		lcla.priority = UILayoutPriorityRequired;

		NSLayoutConstraint *lclt = [NSLayoutConstraint constraintWithItem: effectView.contentView
																attribute: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeTop : NSLayoutAttributeTop
																relatedBy: NSLayoutRelationEqual
																   toItem: label
																attribute: NSLayoutAttributeTop
															   multiplier: 1.0
																 constant: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat ? -4.0 : 0.0];
		lclt.priority = UILayoutPriorityRequired;

		NSLayoutConstraint *lclb = [NSLayoutConstraint constraintWithItem: effectView.contentView
																attribute: lclbAttribute1(self.marginStyle)
																relatedBy: NSLayoutRelationEqual
																   toItem: label
																attribute: NSLayoutAttributeBottom
															   multiplier: 1.0
																 constant: lclbConstant(self.marginStyle)];
		lclb.priority = UILayoutPriorityDefaultHigh;

		NSArray *constraints = @[lcli, lcmil, lcicy, ch, eh, lc2,
								 lc4, lclt, ih, isw, ish,
								 lc6, lclb, lcllm, lcla];

		self.layoutConstraints = constraints;
		[self.contentView addConstraints:constraints];

		self.updatingConstraints = NO;
	}
}

- (void)updateConstraints {
	[super updateConstraints];
	[self invalidateConstraints];
}

+ (void)initialize {
	[super initialize];
	if (self == [MADVibrantTableViewCellImage self]) {
		@autoreleasepool {
			NSArray <Class<UIAppearanceContainer>> *classes = [[NSArray alloc] initWithObjects: self, nil];
			UIButton *button = [UIButton appearanceWhenContainedInInstancesOfClasses: classes];
			[button setBackgroundImage: [UIImage imageNamed:@"MADImageChevronRightTall"]
							  forState: UIControlStateNormal];
		}
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (_initalSetupImageComplete) return;
	
	id <MADVibrantTableViewCellDelegate> vibrantTableViewCellDelegate = self.vibrantTableViewCellDelegate;
	if (vibrantTableViewCellDelegate != nil) {
		_initalSetupImageComplete = YES;
		
		NSArray<__kindof NSLayoutConstraint *> *constraints = self.imageView.constraints;
		if (constraints) {
			[self.imageView removeConstraints:constraints];
		}
		
		NSArray<__kindof NSLayoutConstraint *> *detailLabelConstraints = self.detailTextLabel.constraints;
		if (detailLabelConstraints) {
			[self.detailTextLabel removeConstraints:detailLabelConstraints];
		}
		
		NSArray<__kindof NSLayoutConstraint *> *textLabelConstraints = self.textLabel.constraints;
		if (textLabelConstraints) {
			[self.textLabel removeConstraints:textLabelConstraints];
		}
		
		CGRect viewRect = CGRectMake(CGPointZero.x, CGPointZero.y, 16.0, 16.0);
		UIButton *button = [[UIButton alloc] initWithFrame: viewRect];
		UIImageView *imageView = [[UIImageView alloc] initWithFrame: viewRect];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.translatesAutoresizingMaskIntoConstraints = NO;

		[self.contentView addSubview:imageView];
		_imageViewMain = imageView;
		
		UIBlurEffect *blurEffect = [vibrantTableViewCellDelegate blurEffectForCell:self];
		UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:blurEffect]];
		[visualEffectView.contentView addSubview:button];
		visualEffectView.frame = viewRect;
		self.accessoryView = visualEffectView;
	}
}

+ (UIBlurEffectStyle)blurEffectStyle {
	return UIBlurEffectStyleExtraLight;
}

@end
