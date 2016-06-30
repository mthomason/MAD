//
//  UITabBarController+Shared.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITabBarController_Shared_h
#define Reports_UITabBarController_Shared_h

#import "MADTabBarController.h"

@class NSString;

@interface MADTabBarController (Shared)

    + (instancetype)newTabBarControllerMain:(NSString *)document;

@end

#endif
