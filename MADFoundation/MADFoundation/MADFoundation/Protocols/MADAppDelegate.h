//
//  UIApplication+MADApplicationProtocol.h
//  MADFoundation
//
//  Created by Michael Thomason on 9/23/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADApplicationProtocol.h"

typedef id <UIApplicationDelegate, MADApplicationProtocol> MADAppDelegate;

@interface UIApplication (MADAppDelegate)

+ (MADAppDelegate)AppDelegate;

@end
