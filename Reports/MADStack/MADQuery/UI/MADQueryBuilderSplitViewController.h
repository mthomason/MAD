//
//  MADQueryBuilderContainerController.h
//  MADQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderContainerController_h
#define Reports_MTQueryBuilderContainerController_h

#import <UIKit/UISplitViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import "MADTabBarItemProtocol.h"

@class MADQueryVisualizationViewController, MADNavigationControllerQueryBuilder,
       MADQueryViewController, MADocument;

@interface MADQueryBuilderSplitViewController : UISplitViewController
    <MADViewControllerStandardProtocol,
        MADViewControllerDocumentProtocol,
        MADTabBarImageProtocol>

    + (instancetype)newQueryBuilderSplitViewController:(MADocument *)document;

    - (IBAction)redrawQueryVisualization:(id)sender;

    @property (readwrite, nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

    @property (readonly, nonatomic, strong) MADNavigationControllerQueryBuilder *detailNavigationController;
    @property (readonly, nonatomic, strong) MADQueryVisualizationViewController *queryBuilderControllerAdvanced;
    @property (readonly, nonatomic, strong) MADQueryViewController *queryBuilderController;

@end

#endif
