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

@interface MADBarButtonItemCustom : UIBarButtonItem

+ (instancetype)newBarButtonItemEdit:(id)target action:(SEL)action NS_RETURNS_RETAINED;
+ (instancetype)newBarButtonItemDuplicate:(id)target action:(SEL)action NS_RETURNS_RETAINED;
+ (instancetype)newBarButtonItemEditDone:(id)target action:(SEL)action NS_RETURNS_RETAINED;
+ (instancetype)newBarButtonItemActivityIndicator NS_RETURNS_RETAINED;

@end

#endif
