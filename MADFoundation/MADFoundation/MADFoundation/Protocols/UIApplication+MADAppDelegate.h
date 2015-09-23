//
//  UIApplication+MADAppDelegate.h
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADAppDelegate.h"

@interface UIApplication (MADAppDelegate)

+ (MADAppDelegate)AppDelegate;
+ (BOOL)isMADDesigner;
+ (BOOL)isMADViewer;

@end
