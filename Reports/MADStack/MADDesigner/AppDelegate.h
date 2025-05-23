//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_AppDelegate_h
#define MAD_Designer_AppDelegate_h

#import <UIKit/UIResponder.h>
#import <UIKit/UIApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, MADApplicationProtocol>

@property (nullable, nonatomic, strong) UIWindow *window;

@end

#endif
