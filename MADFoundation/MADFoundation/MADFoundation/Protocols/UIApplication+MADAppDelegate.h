//
//  UIApplication+MADAppDelegate.h
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADFoundation_UIApplication__MADAppDelegate__h
#define MAD_MADFoundation_UIApplication__MADAppDelegate__h

#import "MADAppDelegate.h"

@interface MADApplication : NSObject

+ (MADAppDelegate)AppDelegate;
+ (BOOL)isMADDesigner;
+ (BOOL)isMADViewer;

@end

#endif
