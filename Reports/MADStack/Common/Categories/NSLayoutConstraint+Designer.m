//
//  NSLayoutConstraint+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "NSLayoutConstraint+Designer.h"

@implementation MADLayoutConstraint

+ (NSArray *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
					  marginTop:(CGFloat)marginTop heigh:(CGFloat)height scaleFactor:(CGFloat)scaleFactor {
	NSLayoutConstraint *constraint1,
					   *constraint2;
	constraint1 = [NSLayoutConstraint constraintWithItem: ruler
											   attribute: NSLayoutAttributeHeight
											   relatedBy: NSLayoutRelationEqual
												  toItem: nil
											   attribute: NSLayoutAttributeNotAnAttribute
											  multiplier: scaleFactor
												constant: height];
	
	constraint2 = [NSLayoutConstraint constraintWithItem: ruler
											   attribute: NSLayoutAttributeTop
											   relatedBy: NSLayoutRelationEqual
												  toItem: designer
											   attribute: NSLayoutAttributeTopMargin
											  multiplier: scaleFactor
												constant: marginTop];
	
	return @[constraint1, constraint2];
}

+ (NSArray *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
					 sideMargin:(CGFloat)sideMargin scaleFactor:(CGFloat)scaleFactor {

	NSArray *constraints;
	NSLayoutConstraint *constraint3,
					   *constraint4;
	constraint3 = [NSLayoutConstraint constraintWithItem: ruler
											   attribute: NSLayoutAttributeLeft
											   relatedBy: NSLayoutRelationEqual
												  toItem: designer
											   attribute: NSLayoutAttributeLeft
											  multiplier: scaleFactor
												constant: sideMargin];
	
	constraint4 = [NSLayoutConstraint constraintWithItem: ruler
											   attribute: NSLayoutAttributeRight
											   relatedBy: NSLayoutRelationEqual
												  toItem: designer
											   attribute: NSLayoutAttributeRight
											  multiplier: scaleFactor
												constant: -sideMargin];
	constraints = [[NSArray alloc] initWithObjects:constraint3, constraint4, nil];
	return constraints;
}

+ (instancetype)newLayoutConstraint:(id)view height:(CGFloat)height {
	id constraint = [NSLayoutConstraint constraintWithItem: view
												 attribute: NSLayoutAttributeHeight
												 relatedBy: NSLayoutRelationEqual
													toItem: nil
												 attribute: NSLayoutAttributeNotAnAttribute
												multiplier: 1.0
												  constant: height];
	return constraint;
}

+ (instancetype)newLayoutConstraintContent:(id)container width:(CGFloat)width {
	id constraint = [NSLayoutConstraint constraintWithItem: container
												 attribute: NSLayoutAttributeWidth
												 relatedBy: NSLayoutRelationEqual
													toItem: nil
												 attribute: NSLayoutAttributeNotAnAttribute
												multiplier: 1.0
												  constant: width];
	return constraint;
}

+ (instancetype)newLayoutConstraintViewScrollerTop:(id)item view:(id)toItem {
	id constraint = [NSLayoutConstraint constraintWithItem: item
												 attribute: NSLayoutAttributeTop
												 relatedBy: NSLayoutRelationEqual
													toItem: toItem
												 attribute: NSLayoutAttributeTop
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height {
	id constraint = [NSLayoutConstraint constraintWithItem: label
												 attribute: NSLayoutAttributeHeight
												 relatedBy: NSLayoutRelationEqual
													toItem: nil
												 attribute: NSLayoutAttributeNotAnAttribute
												multiplier: 1.0
												  constant: height];
	return constraint;
}

+ (instancetype)newLayoutConstraintLabelBottom:(UIView *)label container:(UIView *)section
									   padding:(CGFloat)padding {
	id constraint = [NSLayoutConstraint constraintWithItem: label
												 attribute: NSLayoutAttributeBottom
												 relatedBy: NSLayoutRelationEqual
													toItem: section
												 attribute: NSLayoutAttributeBottom
												multiplier: 1.0
												  constant: -padding];
	return constraint;
}

+ (instancetype)newLayoutConstraintLabelRight:(UIView *)label container:(UIView *)section
									  padding:(CGFloat)padding {
	id constraint = [NSLayoutConstraint constraintWithItem: label
												 attribute: NSLayoutAttributeRight
												 relatedBy: NSLayoutRelationEqual
													toItem: section
												 attribute: NSLayoutAttributeRight
												multiplier: 1.0
												  constant: -padding];
	return constraint;
}

+ (instancetype)newLayoutConstraintView:(id)view height:(CGFloat)height {
	id constraint;
	constraint = [self constraintWithItem: view
								attribute: NSLayoutAttributeHeight
								relatedBy: NSLayoutRelationGreaterThanOrEqual
								   toItem: nil
								attribute: NSLayoutAttributeNotAnAttribute
							   multiplier: 1.0
								 constant: height];
	((NSLayoutConstraint *)constraint).priority = UILayoutPriorityDefaultHigh;
	return constraint;
}

+ (instancetype)newLayoutConstraint:(id)view toView:(id)view2 centerX:(CGFloat)centerX {
	id constraint;
	constraint = [self constraintWithItem: view
								attribute: NSLayoutAttributeCenterX
								relatedBy: NSLayoutRelationEqual
								   toItem: view2
								attribute: NSLayoutAttributeLeftMargin
							   multiplier: 1.0
								 constant: centerX];
	return constraint;
}

+ (instancetype)newLayoutConstraint:(id)view toView:(id)view2 centerY:(CGFloat)centerY {
	id constraint;
	constraint = [self constraintWithItem: view
								attribute: NSLayoutAttributeCenterY
								relatedBy: NSLayoutRelationEqual
								   toItem: view2
								attribute: NSLayoutAttributeTopMargin
							   multiplier: 1.0
								 constant: centerY];
	return constraint;
}

+ (instancetype)newLayoutConstraint:(id)view width:(CGFloat)width {
	id constraint;
	constraint = [self constraintWithItem: view
								attribute: NSLayoutAttributeWidth
								relatedBy: NSLayoutRelationEqual
								   toItem: nil
								attribute: NSLayoutAttributeNotAnAttribute
							   multiplier: 1.0
								 constant: width];
	((NSLayoutConstraint *)constraint).priority = UILayoutPriorityDefaultHigh;
	return constraint;
}

+ (instancetype)newLayoutConstraintViewTop:(UIView *)item viewBottom:(UIView *)section
								   padding:(CGFloat)padding {
	id constraint = [NSLayoutConstraint constraintWithItem: item
												 attribute: NSLayoutAttributeBottom
												 relatedBy: NSLayoutRelationEqual
													toItem: section
												 attribute: NSLayoutAttributeTop
												multiplier: 1.0
												  constant: -padding];
	return constraint;
}


+ (instancetype)newLayoutConstraintViewLeft:(UIView *)section content:(UIView *)content
									padding:(CGFloat)padding {
	id constraint = [NSLayoutConstraint constraintWithItem: section
												 attribute: NSLayoutAttributeLeft
												 relatedBy: NSLayoutRelationEqual
													toItem: content
												 attribute: NSLayoutAttributeLeft
												multiplier: 1.0
												  constant: padding];
	return constraint;
}

+ (instancetype)newLayoutConstraintViewRight:(UIView *)section content:(UIView *)content
									 padding:(CGFloat)padding {
	id constraint = [NSLayoutConstraint constraintWithItem: section
												 attribute: NSLayoutAttributeRight
												 relatedBy: NSLayoutRelationEqual
													toItem: content
												 attribute: NSLayoutAttributeRight
												multiplier: 1.0
												  constant: -padding];
	return constraint;
}

+ (instancetype)newLayoutConstraintView:(UIView *)view containerBottom:(UIView *)bottom {
	id constraint = [NSLayoutConstraint constraintWithItem: bottom
												 attribute: NSLayoutAttributeBottom
												 relatedBy: NSLayoutRelationEqual
													toItem: view
												 attribute: NSLayoutAttributeBottom
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintViewBottom:(id)item container:(id)toItem {
	id constraint = [NSLayoutConstraint constraintWithItem: item
												 attribute: NSLayoutAttributeBottom
												 relatedBy: NSLayoutRelationEqual
													toItem: toItem
												 attribute: NSLayoutAttributeTop
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintToolBoxBottom:(id)item container:(id)toItem {
	id constraint = [NSLayoutConstraint constraintWithItem: item
												 attribute: NSLayoutAttributeBottom
												 relatedBy: NSLayoutRelationEqual
													toItem: toItem
												 attribute: NSLayoutAttributeBottom
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintToolboxHeightHidden:(id)item {
	id constraint = [NSLayoutConstraint constraintWithItem: item
												 attribute: NSLayoutAttributeHeight
												 relatedBy: NSLayoutRelationEqual
													toItem: nil
												 attribute: NSLayoutAttributeNotAnAttribute
												multiplier: 0.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintView:(id)view containerLeft:(id)container {
	id constraint = [NSLayoutConstraint constraintWithItem: container
												 attribute: NSLayoutAttributeLeft
												 relatedBy: NSLayoutRelationEqual
													toItem: view
												 attribute: NSLayoutAttributeLeft
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintView:(UIView *)view containerRight:(id)container {
	id constraint = [NSLayoutConstraint constraintWithItem: container
												 attribute: NSLayoutAttributeRight
												 relatedBy: NSLayoutRelationEqual
													toItem: view
												 attribute: NSLayoutAttributeRight
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintView:(UIView *)view containerTop:(id)container {
	id constraint = [NSLayoutConstraint constraintWithItem: container
												 attribute: NSLayoutAttributeTop
												 relatedBy: NSLayoutRelationEqual
													toItem: view
												 attribute: NSLayoutAttributeTop
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintScroller:(id)scroller bottom:(id)bottom {
	id constraint = [NSLayoutConstraint constraintWithItem: scroller
												 attribute: NSLayoutAttributeBottom
												 relatedBy: NSLayoutRelationEqual
													toItem: bottom
												 attribute: NSLayoutAttributeBottom
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

+ (instancetype)newLayoutConstraintToolbarHeightHidden:(id)toolbar {
	id constraint = [NSLayoutConstraint constraintWithItem: toolbar
												 attribute: NSLayoutAttributeHeight
												 relatedBy: NSLayoutRelationEqual
													toItem: nil
												 attribute: NSLayoutAttributeNotAnAttribute
												multiplier: 1.0
												  constant: 0.0];
	return constraint;
}

@end
