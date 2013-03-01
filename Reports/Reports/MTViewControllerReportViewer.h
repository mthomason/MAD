//
//  MUIViewControllerReportViewer.h
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTViewControllerReportPage.h"
#import "MTReportDocument.h"
#import "MTPageViewControllerReport.h"
#import "MTPrintingProtocol.h"

@interface MTViewControllerReportViewer : MTViewController
    <UIPageViewControllerDelegate, UIPageViewControllerDataSource, MTPrintingProtocol>

@property (nonatomic, retain) MTReportDocument *documentReport;

@end