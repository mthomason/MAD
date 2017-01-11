//
//  MADNavigationControllerViewer.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADNavigationControllerViewer_h
#define Reports_MADNavigationControllerViewer_h

#import "MADNavigationController.h"
#import "MADTabBarItemProtocol.h"

@protocol MADViewControllerStandardProtocol;

@interface MADNavigationControllerViewer : MADNavigationController
    <MADTabBarImageProtocol>

@end

#endif
