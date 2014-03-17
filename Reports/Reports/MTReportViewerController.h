//
//  MTReportViewerController2.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerController_h
#define Reports_MTReportViewerController_h

#import <UIKit/UIKit.h>
#import "MTReportViewerReportPageViewController.h"
#import "NSDate+Extras.h"
#import "MUIViewControllerDelegate.h"
#import "MTViewControllerAsyncProtocol.h"
#import "MTActivityReportPrintPreview.h"

@interface MTReportViewerController : UIPageViewController
    <UIPageViewControllerDelegate, UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate, MTPrintingProtocol,
        MTActivityReportPrintPreviewDelegate>

@property (nonatomic, assign) id <MTViewControllerAsyncProtocol> asyncDelegate;
@property (nonatomic, assign) id <MTViewControllerProtocol> viewControllerDelegate;
//@property (nonatomic, retain) MTApplicaitonInstance *applicationInstance;

- (IBAction)print:(id)sender;
- (IBAction)sendToPdf:(id)sender;
- (void)reload:(MTReportViewerController *)reportViewer;
- (void)reload;

@end

#endif
