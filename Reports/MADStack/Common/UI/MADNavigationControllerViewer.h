//
//  MADNavigationControllerViewer.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADNavigationControllerViewer_h
#define Reports_MADNavigationControllerViewer_h

#import <UIKit/UINavigationController.h>
#import "MADTabBarItemProtocol.h"
#import "MADViewControllerDocumentProtocol.h"
#import "MADViewControllerStandardProtocol.h"

@protocol MADViewControllerStandardProtocol;

@interface MADNavigationControllerViewer : UINavigationController
    <MADTabBarImageProtocol,
        MADViewControllerDocumentProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

@end

#endif
