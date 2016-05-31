//
//  UIApplication+MADApplicationProtocol.h
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADFoundation_MADAppDelegate_h
#define MAD_MADFoundation_MADAppDelegate_h

@class UIApplication;
@protocol UIApplicationDelegate;
@protocol MADApplicationProtocol;

typedef id <UIApplicationDelegate, MADApplicationProtocol> MADAppDelegate;

#endif
