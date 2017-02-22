//
//  MADNavigationControllerQuery.h
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADNavigationControllerQuery_h
#define Reports_MADNavigationControllerQuery_h

#import <UIKit/UINavigationController.h>
#import "MADTabBarItemProtocol.h"
#import "MADViewControllerDocumentProtocol.h"
#import "MADViewControllerStandardProtocol.h"

@protocol MADViewControllerStandardProtocol;

@interface MADNavigationControllerQuery : UINavigationController
    <MADTabBarImageProtocol,
        MADViewControllerDocumentProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

@end

#endif
