//
//  UIBarButtonItem+Constructors.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExtensions_UIBarButtonItem_Constructors_h
#define MADExtensions_UIBarButtonItem_Constructors_h

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Constructors)
+ (instancetype)buttonEdit:(id)target action:(SEL)action;
+ (instancetype)buttonDuplicate:(id)target action:(SEL)action;
+ (instancetype)buttonEditDone:(id)target action:(SEL)action;
+ (instancetype)ActivityIndicator;

@end

#endif
