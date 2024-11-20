//
//  MADQueryBuilderContainerController.h
//  MADQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryBuilderContainerController_h
#define Reports_MTQueryBuilderContainerController_h

#import <UIKit/UISplitViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import "MADTabBarItemProtocol.h"

@class MADQueryVisualizationViewController, MADNavigationControllerQueryBuilder,
       MADQueryViewController, MADocument, MADNavigationControllerQueryVisualization;

@interface MADQueryBuilderSplitViewController : UISplitViewController
    <MADViewControllerStandardProtocol,
        MADViewControllerDocumentProtocol,
        MADTabBarImageProtocol>

    + (instancetype)newQueryBuilderSplitViewController:(MADocument *)document;

    - (IBAction)redrawQueryVisualization:(id)sender;

    @property (readwrite, nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

@end

#endif
