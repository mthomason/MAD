//
//  MADLayoutConstraint.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADLayoutConstraint.h"

@implementation MADLayoutConstraint

+ (NSArray *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
					  marginTop:(CGFloat)marginTop heigh:(CGFloat)height scaleFactor:(CGFloat)scaleFactor {
	NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem: ruler
														  attribute: NSLayoutAttributeHeight
														  relatedBy: NSLayoutRelationEqual
															 toItem: nil
														  attribute: NSLayoutAttributeNotAnAttribute
														 multiplier: scaleFactor
														   constant: height];
	
	NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem: ruler
														  attribute: NSLayoutAttributeTop
														  relatedBy: NSLayoutRelationEqual
															 toItem: designer
														  attribute: NSLayoutAttributeTopMargin
														 multiplier: scaleFactor
														   constant: marginTop];
	return @[c1, c2];
}

+ (NSArray *)constraintForRuler:(MADRulerView *)ruler designer:(UIView *)designer
					 sideMargin:(CGFloat)sideMargin scaleFactor:(CGFloat)scaleFactor {
	NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem: ruler
														  attribute: NSLayoutAttributeLeft
														  relatedBy: NSLayoutRelationEqual
															 toItem: designer
														  attribute: NSLayoutAttributeLeft
														 multiplier: scaleFactor
														   constant: sideMargin];
	
	NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem: ruler
														  attribute: NSLayoutAttributeRight
														  relatedBy: NSLayoutRelationEqual
															 toItem: designer
														  attribute: NSLayoutAttributeRight
														 multiplier: scaleFactor
														   constant: -sideMargin];
	return @[c1, c2];
}

+ (NSLayoutConstraint *)LayoutConstraint:(id)view height:(CGFloat)height {
	return [NSLayoutConstraint constraintWithItem: view
										attribute: NSLayoutAttributeHeight
										relatedBy: NSLayoutRelationEqual
										   toItem: nil
										attribute: NSLayoutAttributeNotAnAttribute
									   multiplier: 1.0
										 constant: height];
}

+ (NSLayoutConstraint *)newLayoutConstraintContent:(id)container width:(CGFloat)width {
	return [NSLayoutConstraint constraintWithItem: container
										attribute: NSLayoutAttributeWidth
										relatedBy: NSLayoutRelationEqual
										   toItem: nil
										attribute: NSLayoutAttributeNotAnAttribute
									   multiplier: 1.0
										 constant: width];
}

+ (NSLayoutConstraint *)LayoutConstraintViewScrollerTop:(id)item view:(id)toItem {
	return [NSLayoutConstraint constraintWithItem: item
										attribute: NSLayoutAttributeTop
										relatedBy: NSLayoutRelationEqual
										   toItem: toItem
										attribute: NSLayoutAttributeTop
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintLabel:(UIView *)label toHeight:(CGFloat)height {
	return [NSLayoutConstraint constraintWithItem: label
										attribute: NSLayoutAttributeHeight
										relatedBy: NSLayoutRelationEqual
										   toItem: nil
										attribute: NSLayoutAttributeNotAnAttribute
									   multiplier: 1.0
										 constant: height];
}

+ (NSLayoutConstraint *)LayoutConstraintLabelBottom:(UIView *)label container:(UIView *)section
											padding:(CGFloat)padding {
	return [NSLayoutConstraint constraintWithItem: label
										attribute: NSLayoutAttributeBottom
										relatedBy: NSLayoutRelationEqual
										   toItem: section
										attribute: NSLayoutAttributeBottom
									   multiplier: 1.0
										 constant: -padding];
}

+ (NSLayoutConstraint *)LayoutConstraintLabelRight:(UIView *)label container:(UIView *)section
										   padding:(CGFloat)padding {
	return [NSLayoutConstraint constraintWithItem: label
										attribute: NSLayoutAttributeRight
										relatedBy: NSLayoutRelationEqual
										   toItem: section
										attribute: NSLayoutAttributeRight
									   multiplier: 1.0
										 constant: -padding];
}

+ (NSLayoutConstraint *)LayoutConstraintView:(id)view height:(CGFloat)height {
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: view
																  attribute: NSLayoutAttributeHeight
																  relatedBy: NSLayoutRelationGreaterThanOrEqual
																	 toItem: nil
																  attribute: NSLayoutAttributeNotAnAttribute
																 multiplier: 1.0
																   constant: height];
	constraint.priority = UILayoutPriorityDefaultHigh;
	return constraint;
}

+ (NSLayoutConstraint *)LayoutConstraint:(id)view toView:(id)view2 centerX:(CGFloat)centerX {
	return [NSLayoutConstraint constraintWithItem: view
										attribute: NSLayoutAttributeCenterX
										relatedBy: NSLayoutRelationEqual
										   toItem: view2
										attribute: NSLayoutAttributeLeftMargin
									   multiplier: 1.0
										 constant: centerX];
}

+ (NSLayoutConstraint *)LayoutConstraint:(id)view toView:(id)view2 centerY:(CGFloat)centerY {
	return [NSLayoutConstraint constraintWithItem: view
										attribute: NSLayoutAttributeCenterY
										relatedBy: NSLayoutRelationEqual
										   toItem: view2
										attribute: NSLayoutAttributeTopMargin
									   multiplier: 1.0
										 constant: centerY];
}

+ (NSLayoutConstraint *)LayoutConstraint:(id)view width:(CGFloat)width {
	NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem: view
																   attribute: NSLayoutAttributeWidth
																   relatedBy: NSLayoutRelationEqual
																	  toItem: nil
																   attribute: NSLayoutAttributeNotAnAttribute
																  multiplier: 1.0
																	constant: width];
	constraint.priority = UILayoutPriorityDefaultHigh;
	return constraint;
}

+ (NSLayoutConstraint *)LayoutConstraintViewTop:(UIView *)item viewBottom:(UIView *)section
										padding:(CGFloat)padding {
	return [NSLayoutConstraint constraintWithItem: item
										attribute: NSLayoutAttributeBottom
										relatedBy: NSLayoutRelationEqual
										   toItem: section
										attribute: NSLayoutAttributeTop
									   multiplier: 1.0
										 constant: -padding];
}


+ (NSLayoutConstraint *)LayoutConstraintViewLeft:(UIView *)section content:(UIView *)content
										 padding:(CGFloat)padding {
	return [NSLayoutConstraint constraintWithItem: section
										attribute: NSLayoutAttributeLeft
										relatedBy: NSLayoutRelationEqual
										   toItem: content
										attribute: NSLayoutAttributeLeft
									   multiplier: 1.0
										 constant: padding];
}

+ (NSLayoutConstraint *)LayoutConstraintViewRight:(UIView *)section content:(UIView *)content
										  padding:(CGFloat)padding {
	return [NSLayoutConstraint constraintWithItem: section
										attribute: NSLayoutAttributeRight
										relatedBy: NSLayoutRelationEqual
										   toItem: content
										attribute: NSLayoutAttributeRight
									   multiplier: 1.0
										 constant: -padding];
}

+ (NSLayoutConstraint *)LayoutConstraintView:(UIView *)view containerBottom:(UIView *)bottom {
	return [NSLayoutConstraint constraintWithItem: bottom
										attribute: NSLayoutAttributeBottom
										relatedBy: NSLayoutRelationEqual
										   toItem: view
										attribute: NSLayoutAttributeBottom
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintViewBottom:(id)item container:(id)toItem {
	return [NSLayoutConstraint constraintWithItem: item
										attribute: NSLayoutAttributeBottom
										relatedBy: NSLayoutRelationEqual
										   toItem: toItem
										attribute: NSLayoutAttributeTop
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintToolBoxBottom:(id)item container:(id)toItem {
	return [NSLayoutConstraint constraintWithItem: item
										attribute: NSLayoutAttributeBottom
										relatedBy: NSLayoutRelationEqual
										   toItem: toItem
										attribute: NSLayoutAttributeBottom
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintToolboxHeightHidden:(id)item {
	return [NSLayoutConstraint constraintWithItem: item
										attribute: NSLayoutAttributeHeight
										relatedBy: NSLayoutRelationEqual
										   toItem: nil
										attribute: NSLayoutAttributeNotAnAttribute
									   multiplier: 0.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintView:(id)view containerLeft:(id)container {
	return [NSLayoutConstraint constraintWithItem: container
										attribute: NSLayoutAttributeLeft
										relatedBy: NSLayoutRelationEqual
										   toItem: view
										attribute: NSLayoutAttributeLeft
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintView:(UIView *)view containerRight:(id)container {
	return [NSLayoutConstraint constraintWithItem: container
										attribute: NSLayoutAttributeRight
										relatedBy: NSLayoutRelationEqual
										   toItem: view
										attribute: NSLayoutAttributeRight
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintView:(UIView *)view containerTop:(id)container {
	return [NSLayoutConstraint constraintWithItem: container
										attribute: NSLayoutAttributeTop
										relatedBy: NSLayoutRelationEqual
										   toItem: view
										attribute: NSLayoutAttributeTop
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintScroller:(id)scroller bottom:(id)bottom {
	return [NSLayoutConstraint constraintWithItem: scroller
										attribute: NSLayoutAttributeBottom
										relatedBy: NSLayoutRelationEqual
										   toItem: bottom
										attribute: NSLayoutAttributeBottom
									   multiplier: 1.0
										 constant: 0.0];
}

+ (NSLayoutConstraint *)LayoutConstraintToolbarHeightHidden:(id)toolbar {
	return [NSLayoutConstraint constraintWithItem: toolbar
										attribute: NSLayoutAttributeHeight
										relatedBy: NSLayoutRelationEqual
										   toItem: nil
										attribute: NSLayoutAttributeNotAnAttribute
									   multiplier: 1.0
										 constant: 0.0];
}

@end
