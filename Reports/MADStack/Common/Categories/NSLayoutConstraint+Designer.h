//
//  NSLayoutConstraint+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/4/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSLayoutConstraint_Designer_h
#define Reports_NSLayoutConstraint_Designer_h

#import <UIKit/UIKit.h>

@class MTRulerView;

@interface NSLayoutConstraint (Designer)

+ (NSArray *)ruler:(MTRulerView *)ruler designer:(UIView *)designer marginTop:(CGFloat)marginTop heigh:(CGFloat)height;
+ (NSArray *)ruler:(MTRulerView *)ruler designer:(UIView *)designer sideMargin:(CGFloat)sideMargin;

+ (instancetype)viewScrollerTop:(id)item view:(id)item;
+ (instancetype)viewLeft:(UIView *)section content:(UIView *)content padding:(CGFloat)padding;
+ (instancetype)viewRight:(UIView *)section content:(UIView *)content padding:(CGFloat)padding;
+ (instancetype)label:(UIView *)label toHeight:(CGFloat)height;
+ (instancetype)labelBottom:(UIView *)label container:(UIView *)section padding:(CGFloat)padding;
+ (instancetype)labelRight:(UIView *)label container:(UIView *)section padding:(CGFloat)padding;
+ (instancetype)viewTop:(UIView *)item viewBottom:(UIView *)section padding:(CGFloat)padding;
+ (instancetype)view:(UIView *)view containerBottom:(UIScrollView *)scroller;
+ (instancetype)view:(UIView *)view height:(CGFloat)height;
+ (instancetype)viewBottom:(id)item container:(id)toItem;
+ (instancetype)toolBoxBottom:(id)item container:(id)toItem;
+ (instancetype)toolBoxView:(id)toolbox height:(CGFloat)height;
+ (instancetype)toolboxHeightHidden:(id)item;
+ (instancetype)view:(id)view containerLeft:(id)container;
+ (instancetype)view:(UIView *)view containerRight:(id)container;
+ (instancetype)view:(UIView *)view containerTop:(id)container;
+ (instancetype)scroller:(id)scroller bottom:(id)bottom;
+ (instancetype)toolbarHeightHidden:(id)toolbar;
+ (instancetype)content:(id)container width:(CGFloat)width;

@end

#endif
