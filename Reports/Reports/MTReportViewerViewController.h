//
//  MTReportViewerController2.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTReportViewerReportPageViewController.h"
#import "MAReportDocument.h"
#import "MTPrintingProtocol.h"
#import "NSDate+Extras.h"
#import "DocumentStatusView.h"
#import "MUIViewControllerDelegate.h"
#import "MTViewControllerAsyncProtocol.h"

@interface MTReportViewerController : UIPageViewController
    <UIPageViewControllerDelegate, UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate, MTPrintingProtocol>

@property (nonatomic, assign) id <MTViewControllerAsyncProtocol> asyncDelegate;
@property (nonatomic, assign) id <MTViewControllerProtocol> viewControllerDelegate;

- (IBAction)print:(id)sender;
- (IBAction)sendToPdf:(id)sender;
- (void)reload:(MTReportViewerController *)reportViewer;

@end
