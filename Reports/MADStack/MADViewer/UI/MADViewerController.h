//
//  MADViewerController.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADViewerController_h
#define Reports_MADViewerController_h

#import <UIKit/UIPageViewController.h>

#import <MAD/MADActivityProtocol.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADTabBarItemProtocol.h"
#import "MADOperationRefreshReload.h"
#import "MADOperationRefreshReloadProtocol.h"

@protocol MADViewControllerStandardProtocol;

@interface MADViewerController : UIPageViewController
    <MADViewControllerDocumentProtocol, MADActivityProtocol,
        MADTabBarImageProtocol, MADOperationRefreshReloadProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

    + (instancetype)newViewerController:(MADocument *)document;

    - (IBAction)refresh:(id)sender;
    - (IBAction)zoomToActualSize:(id)sender;
    - (IBAction)zoomToFit:(id)sender;
    - (IBAction)zoomToFullScreen:(id)sender;

@end

#endif
