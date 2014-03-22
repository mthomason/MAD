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
#import "NSDate+Extras.h"
#import "MUIViewControllerDelegate.h"
#import "MTViewControllerAsyncProtocol.h"

@interface MTReportViewerController : UIPageViewController
    <UIPageViewControllerDelegate, UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate>

@property (nonatomic, assign) id <MTViewControllerAsyncProtocol> asyncDelegate;
@property (nonatomic, assign) id <MTViewControllerProtocol> viewControllerDelegate;

- (IBAction)print:(id)sender;
- (IBAction)sendToPdf:(id)sender;
- (void)reload:(MTReportViewerController *)reportViewer;
- (void)reload;

@end

#endif
