//
//  MUIViewControllerReportViewer.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"

@interface MUIViewControllerReportViewer : MTViewController
    <UIPageViewControllerDelegate>

- (IBAction)done:(id)sender;

@end