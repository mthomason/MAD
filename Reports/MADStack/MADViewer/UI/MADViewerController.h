//
//  MADViewerController.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerController_h
#define Reports_MTReportViewerController_h

#import "MADViewController.h"
#import <MAD/MADActivityProtocol.h>
#import "MADocumentProtocol.h"

@protocol MTViewControllerProtocol;

@interface MADViewerController : MADPageViewController
    <MADViewControllerDocumentProtocol,
        MADActivityProtocol,
        UIPageViewControllerDelegate,
        UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate>

    @property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;
    @property (nonatomic, weak) MADocument *document;

    - (IBAction)reload;
    - (IBAction)refresh:(id)sender;
    - (IBAction)zoomToActualSize:(id)sender;
    - (IBAction)zoomToFit:(id)sender;
    - (IBAction)zoomToFullScreen:(id)sender;

@end

#endif
