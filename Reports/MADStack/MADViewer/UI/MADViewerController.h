//
//  MADViewerController.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerController_h
#define Reports_MTReportViewerController_h

#import "MADPageViewController.h"

#import "MADViewControllerDocumentProtocol.h"
#import <MAD/MADActivityProtocol.h>

@protocol MADViewControllerStandardProtocol;

@interface MADViewerController : MADPageViewController
    <MADViewControllerDocumentProtocol,
        MADActivityProtocol>

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

    + (instancetype)newViewerController:(MADocument *)document;

    - (IBAction)refresh:(id)sender;
    - (IBAction)zoomToActualSize:(id)sender;
    - (IBAction)zoomToFit:(id)sender;
    - (IBAction)zoomToFullScreen:(id)sender;

@end

#endif
