//
//  UIApplication+Helpers.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/6/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADExtensions_UIApplication_Constructors_h
#define MADExtensions_UIApplication_Constructors_h

#import <UIKit/UIViewController.h>

@interface UIApplication (Helpers)

+ (__kindof UIViewController *)topViewController NS_RETURNS_NOT_RETAINED;
@property(nonatomic,readonly) UIWindow *safeKeyWindow;

@end

#endif
