//
//  UIBarButtonItem+Constructors.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExtensions_UIBarButtonItem_Constructors_h
#define MADExtensions_UIBarButtonItem_Constructors_h

#import <UIKit/UIBarButtonItem.h>

@interface UIBarButtonItem (Constructors)

    + (instancetype)newBarButtonItemEdit:(id)target action:(SEL)action;
    + (instancetype)newBarButtonItemDuplicate:(id)target action:(SEL)action;
    + (instancetype)newBarButtonItemEditDone:(id)target action:(SEL)action;
    + (instancetype)newBarButtonItemActivityIndicator;

@end

#endif
