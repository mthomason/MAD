//
//  MUIViewControllerReportViewer.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MUIViewControllerReportViewer, UIManagedDocumentQuery;

@protocol MUIViewControllerReportViewerDelegate
- (void)viewControllerReportViewerDidFinish:(MUIViewControllerReportViewer *)controller;
@end

@interface MUIViewControllerReportViewer : UIViewController
    <UIPageViewControllerDelegate>

@property (assign) IBOutlet id <MUIViewControllerReportViewerDelegate> delegate;

- (IBAction)done:(id)sender;

@end