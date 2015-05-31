//
//  UIBarButtonItem+Constructors.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Constructors)
+ (UIBarButtonItem *)buttonEdit:(id)target action:(SEL)action;
+ (UIBarButtonItem *)buttonDuplicate:(id)target action:(SEL)action;
+ (UIBarButtonItem *)buttonEditDone:(id)target action:(SEL)action;

@end
