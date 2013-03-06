//
//  MUIViewControllerReportViewer.h
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTReportViewerReportPageViewController.h"
#import "MTReportDocument.h"
#import "MTReportViewerReportViewController.h"
#import "MTPrintingProtocol.h"

@interface MTReportViewerViewController : MTViewController
    <UIPageViewControllerDelegate, UIPageViewControllerDataSource, MTPrintingProtocol>

@property (nonatomic, retain) MTReportDocument *documentReport;
@property (nonatomic, retain) MTReportViewerPrintPageRenderer *printPageRendererReport;

@end
