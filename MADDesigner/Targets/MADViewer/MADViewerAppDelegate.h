//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADViewerAppDelegate_h
#define MAD_Designer_MADViewerAppDelegate_h

#import <UIKit/UIResponder.h>
#import <UIKit/UIApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

@interface MADViewerAppDelegate : UIResponder
    <UIApplicationDelegate, MADApplicationProtocol>

    @property (nonatomic, strong) UIWindow *window;

@end

#endif
