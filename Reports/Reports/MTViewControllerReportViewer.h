//
//  MUIViewControllerReportViewer.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTViewControllerReportPage.h"
#import "MNSDocumentReport.h"
#import "MTPageViewControllerReport.h"

@interface MTViewControllerReportViewer : MTViewController
    <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic, retain) MNSDocumentReport *documentReport;

@end