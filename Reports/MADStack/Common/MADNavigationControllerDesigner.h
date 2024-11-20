//
//  MADNavigationControllerDesigner.h
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADNavigationControllerDesigner_h
#define Reports_MADNavigationControllerDesigner_h

#import <UIKit/UINavigationController.h>
#import "MADTabBarItemProtocol.h"
#import "MADViewControllerDocumentProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>

@protocol MADViewControllerStandardProtocol;

@interface MADNavigationControllerDesigner : UINavigationController
    <MADTabBarImageProtocol,
        MADViewControllerDocumentProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

@end

#endif
