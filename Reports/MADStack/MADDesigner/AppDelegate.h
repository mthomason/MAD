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
#import <MADFoundation/MADApplicationProtocol.h>

@interface AppDelegate : UIResponder
    <UIApplicationDelegate, MADApplicationProtocol>

@property (nonatomic, strong) UIWindow *window;

@end

#endif
