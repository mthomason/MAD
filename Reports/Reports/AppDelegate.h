//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_AppDelegate_h
#define MAD_Designer_AppDelegate_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

@class MADAppConfiguration;

@interface AppDelegate : UIResponder
    <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong, readonly) MADAppConfiguration *appConfiguration;

@end

#endif