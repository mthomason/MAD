//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_AppDelegate_h
#define MAD_Designer_AppDelegate_h

#import <UIKit/UIResponder.h>
#import <UIKit/UIApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, MADApplicationProtocol>

@property (nullable, nonatomic, strong) UIWindow *window;

/// The generated per-build identity (MADBuildInfo.plist), or nil when this build
/// did not produce one.  Never reads or writes a tracked plist.
+ (nullable NSDictionary *)buildInfoForBundle:(nullable NSBundle *)bundle;

@end

#endif
